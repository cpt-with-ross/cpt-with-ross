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
# 3. Retrieves user's active stuck points for personalized context
# 4. Constructs a system prompt with retrieved context
# 5. Orchestrates the LLM conversation with streaming support
#
# The service intentionally bypasses acts_as_chat's automatic message creation
# to maintain control over message persistence in the ChatResponseJob.
#
class CptChatService
  # Cosine distance thresholds for knowledge retrieval (lower = more similar)
  RELEVANCE_THRESHOLD = 0.35  # Primary threshold for including chunks
  FALLBACK_THRESHOLD = 0.5    # Looser threshold when no primary matches found
  CANDIDATE_COUNT = 20        # Number of vector search candidates to consider

  def initialize(chat, user)
    @chat = chat
    @user = user
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
  def ask(user_message, &block)
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
    llm_chat.ask(user_message, &block)
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
  # fresh knowledge retrieval results.
  def build_system_prompt(manual_context, stuck_points)
    <<~PROMPT
      You are Ross, a supportive and knowledgeable AI therapist assistant specializing in Cognitive Processing Therapy (CPT) for PTSD.

      PATIENT CONTEXT:
      Active Stuck Points: #{stuck_points.presence || 'None identified yet'}

      CLINICAL GUIDELINES (Use only if relevant to the conversation):
      #{manual_context.presence || 'No specific guidelines retrieved for this query.'}

      YOUR ROLE:
      - Guide users through CPT exercises and concepts with warmth and empathy
      - Help users understand their stuck points, complete ABC worksheets, and develop alternative thoughts
      - Be encouraging but maintain professional therapeutic boundaries
      - When using information from the clinical guidelines, integrate it naturally into your response

      COMMUNICATION STYLE:
      - Warm, supportive, and non-judgmental
      - Clear and educational when explaining CPT concepts
      - Patient and understanding of the difficulty of trauma work
      - Encourage self-reflection without being pushy

      IMPORTANT:
      - You are an AI assistant, not a replacement for professional therapy
      - Encourage users to work with their therapist for complex issues
      - If a user appears to be in crisis, provide crisis resources (988 Suicide & Crisis Lifeline)
      - If the user asks something unrelated to CPT or mental health, answer politely but briefly
    PROMPT
  end
end
