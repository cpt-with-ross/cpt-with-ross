# frozen_string_literal: true

# =============================================================================
# CptChatService - AI Chat Orchestration for Cognitive Processing Therapy
# =============================================================================
#
# This service manages the interaction between users and the AI therapist ("Ross")
# by implementing a Retrieval-Augmented Generation (RAG) pattern:
#
# 1. Embeds user queries using an embedding model (OpenAI/Anthropic)
# 2. Performs semantic similarity search against CPT clinical knowledge base
# 3. Retrieves user's full therapy context (index events, worksheets, etc.)
# 4. Constructs a system prompt with retrieved context and optional focus
# 5. Orchestrates the LLM conversation with streaming support
#
# The service intentionally bypasses acts_as_chat's automatic message creation
# to maintain control over message persistence in the ChatResponseJob.
#
# Focus Context:
# When the user is viewing a specific worksheet or stuck point, pass focus: hash
# to prioritize that context in the system prompt. Supported focus types:
# - { index_event: IndexEvent }
# - { stuck_point: StuckPoint }
# - { abc_worksheet: AbcWorksheet }
# - { alternative_thought: AlternativeThought }
# - { impact_statement: ImpactStatement }
#
# rubocop:disable Metrics/ClassLength
class CptChatService
  # Cosine distance thresholds for knowledge retrieval (lower = more similar)
  RELEVANCE_THRESHOLD = 0.35  # Primary threshold for including chunks
  FALLBACK_THRESHOLD = 0.5    # Looser threshold when no primary matches found
  CANDIDATE_COUNT = 20        # Number of vector search candidates to consider

  def initialize(chat, user, focus: {})
    @chat = chat
    @user = user
    @focus = focus
  end

  # Processes a user message and generates an AI response with RAG context.
  #
  # This method:
  # 1. Retrieves relevant CPT knowledge via semantic search
  # 2. Fetches user's unresolved stuck points for personalization
  # 3. Reconstructs conversation history for multi-turn context
  # 4. Streams the LLM response via the provided block
  #
  # The block receives streaming chunks for real-time UI updates via ActionCable.
  def ask(user_message, &)
    manual_context = retrieve_relevant_knowledge(user_message)
    stuck_points_context = retrieve_stuck_points
    system_prompt = build_system_prompt(manual_context, stuck_points_context)

    # Reconstruct conversation history, excluding system messages which are
    # injected fresh each turn with updated RAG context
    messages = @chat.messages.where.not(role: 'system').order(:created_at).map do |msg|
      { role: msg.role.to_sym, content: msg.content }
    end

    # Prevent duplicate if the user message was already persisted before this call
    messages << { role: :user, content: user_message } unless messages.last&.dig(:content) == user_message

    # Bypass acts_as_chat to prevent automatic message creation - we handle
    # persistence manually in ChatResponseJob for better error handling
    llm_chat = RubyLLM.chat(model: @chat.llm_model_id, provider: @chat.llm_provider.to_sym)
    llm_chat.with_instructions(system_prompt)

    # Replay conversation history (all but the current message)
    messages[0..-2].each do |msg|
      llm_chat.add_message(role: msg[:role], content: msg[:content])
    end

    # Stream the response - block receives chunks for ActionCable broadcast
    llm_chat.ask(user_message, &)
  end

  private

  # Performs semantic search against the CPT knowledge base using pgvector.
  #
  # Uses a two-tier threshold strategy:
  # 1. Primary: Include all chunks below RELEVANCE_THRESHOLD (highly relevant)
  # 2. Fallback: If no primary matches, include best match if below FALLBACK_THRESHOLD
  #
  # This ensures users always get some context when available, while prioritizing
  # the most semantically similar content.
  def retrieve_relevant_knowledge(query)
    return '' if KnowledgeChunk.none?

    query_embedding = embed_query(query)
    return '' if query_embedding.nil?

    # pgvector's nearest_neighbors returns results sorted by distance (ascending)
    candidates = KnowledgeChunk
                 .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
                 .first(CANDIDATE_COUNT)

    # Filter to only highly relevant chunks
    relevant_chunks = candidates.select { |chunk| chunk.neighbor_distance < RELEVANCE_THRESHOLD }

    # Fallback: if nothing passed the strict threshold, use the best match
    # if it's at least somewhat relevant (below looser threshold)
    if relevant_chunks.empty?
      best_match = candidates.first
      relevant_chunks = [best_match] if best_match && best_match.neighbor_distance < FALLBACK_THRESHOLD
    end

    relevant_chunks.map(&:content).join("\n\n")
  end

  # Generates a vector embedding for the query text using the configured
  # embedding model (typically OpenAI text-embedding-3-small or similar).
  #
  # Returns nil on failure to allow graceful degradation - the chat will
  # proceed without RAG context rather than failing entirely.
  def embed_query(text)
    config = Rails.application.config.cpt_chat
    response = RubyLLM.embed(
      text,
      model: config[:embedding_model_id],
      provider: config[:embedding_provider].to_sym
    )
    response.vectors
  rescue StandardError => e
    Rails.logger.error("Query embedding failed: #{e.message}")
    nil
  end

  # Retrieves the user's unresolved stuck points for context injection.
  # Stuck points are core negative beliefs identified during CPT therapy.
  def retrieve_stuck_points
    @user.stuck_points.where(resolved: [false, nil]).pluck(:statement).join('; ')
  end

  # Constructs the system prompt that defines Ross's persona and injects
  # retrieved RAG context. This prompt is regenerated each turn to include
  # fresh knowledge retrieval results and full patient therapy context.
  def build_system_prompt(manual_context, stuck_points)
    focused_context = build_focused_context
    patient_context = build_patient_context

    <<~PROMPT
      You are Ross, a supportive and knowledgeable AI therapist assistant specializing in Cognitive Processing Therapy (CPT) for PTSD.
      #{focused_context}
      PATIENT'S THERAPY PROGRESS:
      #{patient_context.presence || 'No therapy work recorded yet.'}

      ACTIVE STUCK POINTS (Unresolved):
      #{stuck_points.presence || 'None identified yet'}

      CLINICAL GUIDELINES (Use only if relevant to the conversation):
      #{manual_context.presence || 'No specific guidelines retrieved for this query.'}

      YOUR ROLE:
      - Guide users through CPT exercises and concepts with warmth and empathy
      - Help users understand their stuck points, complete ABC worksheets, and develop alternative thoughts
      - Be encouraging but maintain professional therapeutic boundaries
      - When using information from the clinical guidelines, integrate it naturally into your response
      - Reference the patient's specific worksheets and progress when relevant to provide personalized guidance

      COMMUNICATION STYLE:
      - Keep responses concise—no longer than a typical text message (1-3 sentences max)
      - Be Socratic: ask one focused question to guide self-discovery rather than lecturing
      - Make every response actionable—give the user something specific to reflect on or do
      - Warm and non-judgmental, but brief

      IMPORTANT:
      - You are an AI assistant, not a replacement for professional therapy
      - Encourage users to work with their therapist for complex issues
      - If a user appears to be in crisis, provide crisis resources (988 Suicide & Crisis Lifeline)
      - If the user asks something unrelated to CPT or mental health, answer politely but briefly
    PROMPT
  end

  # Builds context for the currently focused item (what the user is viewing).
  # This appears prominently at the top of the system prompt.
  def build_focused_context
    return '' if @focus.empty?

    content = format_focus_item
    return '' if content.blank?

    <<~FOCUS

      CURRENTLY VIEWING (User is focused on this - prioritize in your responses):
      #{content}
    FOCUS
  end

  # Formats the focused item based on its type
  def format_focus_item
    if @focus[:index_event]
      format_index_event(@focus[:index_event], include_nested: true)
    elsif @focus[:stuck_point]
      format_stuck_point_detailed(@focus[:stuck_point])
    elsif @focus[:abc_worksheet]
      format_abc_worksheet_detailed(@focus[:abc_worksheet])
    elsif @focus[:alternative_thought]
      format_alternative_thought_detailed(@focus[:alternative_thought])
    elsif @focus[:impact_statement]
      format_impact_statement_detailed(@focus[:impact_statement])
    end
  end

  # Builds the complete patient therapy context from all index events and worksheets.
  # Uses eager loading to minimize database queries.
  def build_patient_context
    sections = []

    @user.index_events
         .includes(:impact_statement, stuck_points: %i[abc_worksheets alternative_thoughts])
         .find_each do |event|
      # Skip detailed formatting if this event is already the focus
      next if @focus[:index_event]&.id == event.id

      sections << format_index_event(event)
    end

    sections.join("\n\n---\n\n")
  end

  # Formats an index event with its nested resources
  def format_index_event(event, include_nested: false)
    lines = ["### Index Event: #{event.title}"]
    lines << "Date: #{event.date}" if event.date.present?

    if event.impact_statement&.statement.present?
      lines << "\n**Impact Statement:**"
      lines << truncate_content(event.impact_statement.statement, 600)
    end

    event.stuck_points.each do |sp|
      # Skip if this stuck point is the current focus (avoid duplication)
      next if @focus[:stuck_point]&.id == sp.id

      lines << format_stuck_point(sp, include_worksheets: include_nested)
    end

    lines.join("\n")
  end

  # Formats a stuck point with optional worksheet details
  # rubocop:disable Metrics/PerceivedComplexity
  def format_stuck_point(stuck_point, include_worksheets: false)
    status = stuck_point.resolved? ? 'Resolved' : 'Working on it'
    lines = ["\n**Stuck Point:** #{stuck_point.statement}"]
    lines << "Status: #{status}"
    lines << "Belief Type: #{stuck_point.belief_type}" if stuck_point.belief_type.present?

    if include_worksheets
      stuck_point.abc_worksheets.each do |abc|
        next if @focus[:abc_worksheet]&.id == abc.id

        lines << format_abc_worksheet(abc)
      end

      stuck_point.alternative_thoughts.each do |alt|
        next if @focus[:alternative_thought]&.id == alt.id

        lines << format_alternative_thought(alt)
      end
    else
      abc_count = stuck_point.abc_worksheets.size
      alt_count = stuck_point.alternative_thoughts.size
      lines << "ABC Worksheets: #{abc_count}" if abc_count.positive?
      lines << "Alternative Thoughts: #{alt_count}" if alt_count.positive?
    end

    lines.join("\n")
  end
  # rubocop:enable Metrics/PerceivedComplexity

  # Detailed format for a focused stuck point (includes all nested worksheets)
  def format_stuck_point_detailed(stuck_point)
    event = stuck_point.index_event
    lines = ["**From Index Event:** #{event.title}"]
    lines << "**Stuck Point:** #{stuck_point.statement}"
    lines << "**Status:** #{stuck_point.resolved? ? 'Resolved' : 'Working on it'}"
    lines << "**Belief:** #{stuck_point.belief}" if stuck_point.belief.present?
    lines << "**Belief Type:** #{stuck_point.belief_type}" if stuck_point.belief_type.present?

    if stuck_point.abc_worksheets.any?
      lines << "\n**ABC Worksheets:**"
      stuck_point.abc_worksheets.each { |abc| lines << format_abc_worksheet(abc) }
    end

    if stuck_point.alternative_thoughts.any?
      lines << "\n**Alternative Thoughts:**"
      stuck_point.alternative_thoughts.each { |alt| lines << format_alternative_thought(alt) }
    end

    lines.join("\n")
  end

  # Compact format for ABC worksheet in listings
  def format_abc_worksheet(abc)
    <<~ABC.strip
      - ABC Worksheet: #{abc.title}
        A (Activating Event): #{truncate_content(abc.activating_event, 200)}
        B (Beliefs): #{truncate_content(abc.beliefs, 200)}
        C (Consequences): #{truncate_content(abc.consequences, 200)}
    ABC
  end

  # Detailed format for a focused ABC worksheet
  def format_abc_worksheet_detailed(abc)
    stuck_point = abc.stuck_point
    event = stuck_point.index_event

    <<~ABC
      **From Index Event:** #{event.title}
      **Related Stuck Point:** #{stuck_point.statement}

      **ABC Worksheet: #{abc.title}**
      **A (Activating Event):**
      #{abc.activating_event}

      **B (Beliefs):**
      #{abc.beliefs}

      **C (Consequences):**
      #{abc.consequences}
    ABC
  end

  # Compact format for alternative thought in listings
  def format_alternative_thought(alt)
    <<~ALT.strip
      - Alternative Thought: #{alt.title}
        Unbalanced: #{truncate_content(alt.unbalanced_thought, 200)}
        Balanced: #{truncate_content(alt.balanced_thought, 200)}
    ALT
  end

  # Detailed format for a focused alternative thought
  def format_alternative_thought_detailed(alt)
    stuck_point = alt.stuck_point
    event = stuck_point.index_event

    <<~ALT
      **From Index Event:** #{event.title}
      **Related Stuck Point:** #{stuck_point.statement}

      **Alternative Thought: #{alt.title}**
      **Unbalanced Thought:**
      #{alt.unbalanced_thought}

      **Balanced Thought:**
      #{alt.balanced_thought}
    ALT
  end

  # Detailed format for a focused impact statement
  def format_impact_statement_detailed(impact)
    event = impact.index_event

    <<~IMPACT
      **From Index Event:** #{event.title}

      **Impact Statement:**
      #{impact.statement}
    IMPACT
  end

  # Truncates long content to avoid excessive token usage while preserving meaning
  def truncate_content(text, max_length = 300)
    return '' if text.blank?
    return text if text.length <= max_length

    "#{text[0, max_length]}..."
  end
end
# rubocop:enable Metrics/ClassLength
