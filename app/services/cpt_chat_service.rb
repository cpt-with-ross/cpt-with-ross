# Service for handling CPT chat interactions with dynamic RAG retrieval.
# Embeds user queries, retrieves relevant knowledge, and includes user context.
class CptChatService
  RELEVANCE_THRESHOLD = 0.35
  FALLBACK_THRESHOLD = 0.5
  CANDIDATE_COUNT = 20

  def initialize(chat, user)
    @chat = chat
    @user = user
  end

  def ask(user_message, &block)
    manual_context = retrieve_relevant_knowledge(user_message)
    stuck_points_context = retrieve_stuck_points
    system_prompt = build_system_prompt(manual_context, stuck_points_context)

    # Build conversation history from existing messages (exclude system messages)
    messages = @chat.messages.where.not(role: 'system').order(:created_at).map do |msg|
      { role: msg.role.to_sym, content: msg.content }
    end

    # Add the current user message if not already in history
    messages << { role: :user, content: user_message } unless messages.last&.dig(:content) == user_message

    # Use RubyLLM.chat directly to avoid acts_as_chat creating duplicate messages
    llm_chat = RubyLLM.chat(model: @chat.llm_model_id, provider: @chat.llm_provider.to_sym)
    llm_chat.with_instructions(system_prompt)

    # Add history
    messages[0..-2].each do |msg|
      llm_chat.add_message(role: msg[:role], content: msg[:content])
    end

    # Ask with the latest message and stream
    llm_chat.ask(user_message, &block)
  end

  private

  def retrieve_relevant_knowledge(query)
    return '' if KnowledgeChunk.none?

    query_embedding = embed_query(query)
    return '' if query_embedding.nil?

    candidates = KnowledgeChunk
                 .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
                 .first(CANDIDATE_COUNT)

    relevant_chunks = candidates.select { |chunk| chunk.neighbor_distance < RELEVANCE_THRESHOLD }

    if relevant_chunks.empty?
      best_match = candidates.first
      relevant_chunks = [best_match] if best_match && best_match.neighbor_distance < FALLBACK_THRESHOLD
    end

    relevant_chunks.map(&:content).join("\n\n")
  end

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

  def retrieve_stuck_points
    @user.stuck_points.where(resolved: [false, nil]).pluck(:statement).join('; ')
  end

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
