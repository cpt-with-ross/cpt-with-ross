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
# - { baseline: Baseline }
#
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

  # Retrieves the user's stuck points for context injection.
  # Stuck points are core negative beliefs identified during CPT therapy.
  def retrieve_stuck_points
    @user.stuck_points.pluck(:statement).join('; ')
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

      STUCK POINTS:
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
    elsif @focus[:baseline]
      format_baseline_detailed(@focus[:baseline])
    end
  end

  # Builds the complete patient therapy context from all index events and worksheets.
  # Uses eager loading to minimize database queries.
  def build_patient_context
    sections = []

    @user.index_events
         .includes(:baseline, stuck_points: %i[abc_worksheets alternative_thoughts])
         .find_each do |event|
      # Skip detailed formatting if this event is already the focus
      next if @focus[:index_event]&.id == event.id

      sections << format_index_event(event)
    end

    sections.join("\n\n---\n\n")
  end

  # Formats an index event with its nested resources
  # rubocop:disable Metrics/PerceivedComplexity
  def format_index_event(event, include_nested: false)
    lines = ["### Index Event: #{event.title}"]
    lines << "Date: #{event.date}" if event.date.present?

    # Add PCL-5 severity indicator if baseline is complete
    if event.baseline&.pcl_complete?
      score = event.baseline.pcl_total_score
      lines << "PTSD Severity: #{score}/80 (#{pcl_severity_label(score)})"
    end

    if event.baseline&.statement.present?
      lines << "\n**Impact Statement:**"
      lines << truncate_content(event.baseline.statement, 600)
    end

    event.stuck_points.each do |sp|
      # Skip if this stuck point is the current focus (avoid duplication)
      next if @focus[:stuck_point]&.id == sp.id

      lines << format_stuck_point(sp, include_worksheets: include_nested)
    end

    lines.join("\n")
  end
  # rubocop:enable Metrics/PerceivedComplexity

  # Formats a stuck point with optional worksheet details
  # rubocop:disable Metrics/PerceivedComplexity
  def format_stuck_point(stuck_point, include_worksheets: false)
    lines = ["\n**Stuck Point:** #{stuck_point.statement}"]

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
    emotions_summary = if abc.emotions.present? && abc.emotions.any?
                         top = abc.emotions.max_by { |e| e['intensity'].to_i }
                         " (Primary emotion: #{top['emotion']} #{top['intensity']}/10)"
                       else
                         ''
                       end

    <<~ABC.strip
      - ABC Worksheet: #{abc.title}#{emotions_summary}
        A: #{truncate_content(abc.activating_event, 150)}
        B: #{truncate_content(abc.beliefs, 150)}
        C: #{truncate_content(abc.consequences, 150)}
    ABC
  end

  # Detailed format for a focused ABC worksheet
  def format_abc_worksheet_detailed(abc)
    stuck_point = abc.stuck_point
    event = stuck_point.index_event

    lines = [
      "**From Index Event:** #{event.title}",
      "**Related Stuck Point:** #{stuck_point.statement}",
      '',
      "**ABC Worksheet: #{abc.title}**",
      '**A (Activating Event):**',
      abc.activating_event.to_s,
      '',
      '**B (Beliefs):**',
      abc.beliefs.to_s,
      '',
      '**C (Consequences):**',
      abc.consequences.to_s
    ]

    # Add emotions if present
    if abc.emotions.present? && abc.emotions.any?
      lines << ''
      lines << '**Emotions Experienced:**'
      lines << format_emotions(abc.emotions)
    end

    lines.join("\n")
  end

  # Compact format for alternative thought in listings
  def format_alternative_thought(alt)
    belief_change = if alt.stuck_point_belief_before.present? && alt.stuck_point_belief_after.present?
                      " (Belief: #{alt.stuck_point_belief_before}% → #{alt.stuck_point_belief_after}%)"
                    else
                      ''
                    end

    <<~ALT.strip
      - Alternative Thought: #{alt.title}#{belief_change}
        Original: #{truncate_content(alt.stuck_point&.statement, 150)}
        Alternative: #{truncate_content(alt.alternative_thought, 150)}
    ALT
  end

  # Detailed format for a focused alternative thought
  # rubocop:disable Metrics/PerceivedComplexity
  def format_alternative_thought_detailed(alt)
    stuck_point = alt.stuck_point
    event = stuck_point.index_event

    lines = [
      "**From Index Event:** #{event.title}",
      "**Related Stuck Point:** #{stuck_point.statement}",
      '',
      "**Alternative Thought Worksheet: #{alt.title}**"
    ]

    # Section B: Initial belief rating
    if alt.stuck_point_belief_before.present?
      lines << "**Initial Belief in Stuck Point:** #{alt.stuck_point_belief_before}%"
    end

    # Section C: Emotions before
    if alt.emotions_before.present? && alt.emotions_before.any?
      lines << '**Emotions Before:**'
      lines << format_emotions(alt.emotions_before)
    end

    # Section D: Exploring questions (only answered ones)
    exploring = format_exploring_questions(alt)
    if exploring.present?
      lines << ''
      lines << '**Exploring the Stuck Point:**'
      lines << exploring
    end

    # Section E: Thinking patterns (only identified ones)
    patterns = format_thinking_patterns(alt)
    if patterns.present?
      lines << ''
      lines << '**Thinking Patterns Identified:**'
      lines << patterns
    end

    # Section F: Alternative thought
    if alt.alternative_thought.present?
      lines << ''
      lines << '**Alternative Thought:**'
      lines << alt.alternative_thought
      if alt.alternative_thought_belief.present?
        lines << "**Belief in Alternative:** #{alt.alternative_thought_belief}%"
      end
    end

    # Section G: Re-rated stuck point
    if alt.stuck_point_belief_after.present?
      lines << "**Updated Belief in Stuck Point:** #{alt.stuck_point_belief_after}%"
    end

    # Section H: Emotions after
    if alt.emotions_after.present? && alt.emotions_after.any?
      lines << '**Emotions After:**'
      lines << format_emotions(alt.emotions_after)
    end

    lines.join("\n")
  end
  # rubocop:enable Metrics/PerceivedComplexity

  # Detailed format for a focused baseline
  def format_baseline_detailed(baseline)
    event = baseline.index_event
    lines = ["**From Index Event:** #{event.title}"]

    # PCL-5 severity (0-80 scale)
    if baseline.pcl_complete?
      score = baseline.pcl_total_score
      severity = pcl_severity_label(score)
      lines << "**PTSD Severity (PCL-5):** #{score}/80 (#{severity})"
    end

    # Event context
    lines << "**Time Since Event:** #{baseline.time_since_event}" if baseline.time_since_event.present?
    if baseline.experience_type.present?
      lines << "**Experience Type:** #{Baseline::EXPERIENCE_TYPES[baseline.experience_type]}"
    end

    # Impact statement
    if baseline.statement.present?
      lines << "\n**Impact Statement:**"
      lines << baseline.statement
    end

    lines.join("\n")
  end

  # Format emotions array as readable string
  def format_emotions(emotions_array)
    return '' unless emotions_array.is_a?(Array) && emotions_array.any?

    emotions_array.map do |e|
      "#{e['emotion'].capitalize}: #{e['intensity']}/10"
    end.join(', ')
  end

  # Format exploring questions (only answered ones)
  def format_exploring_questions(alt)
    answers = AlternativeThought::EXPLORING_QUESTIONS.filter_map do |field, question|
      answer = alt.send(field)
      next if answer.blank?

      "- #{question} #{truncate_content(answer, 200)}"
    end
    answers.join("\n")
  end

  # Format thinking patterns (only identified ones)
  def format_thinking_patterns(alt)
    patterns = AlternativeThought::THINKING_PATTERNS.filter_map do |field, label|
      answer = alt.send(field)
      next if answer.blank?

      "- #{label}: #{truncate_content(answer, 150)}"
    end
    patterns.join("\n")
  end

  # Helper for PCL-5 severity interpretation
  def pcl_severity_label(score)
    case score
    when 0..10 then 'Minimal'
    when 11..32 then 'Mild to Moderate'
    when 33..49 then 'Moderate to High'
    else 'High (clinical threshold)'
    end
  end

  # Truncates long content to avoid excessive token usage while preserving meaning
  def truncate_content(text, max_length = 300)
    return '' if text.blank?
    return text if text.length <= max_length

    "#{text[0, max_length]}..."
  end
end
# rubocop:enable Metrics/ClassLength
