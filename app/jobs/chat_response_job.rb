# frozen_string_literal: true

# =============================================================================
# ChatResponseJob - Real-time AI Response Streaming
# =============================================================================
#
# Processes user chat messages and streams AI responses via ActionCable.
# This job runs in the 'critical' queue for low latency user experience.
#
# Flow:
# 1. User sends message -> MessagesController creates placeholder assistant message
# 2. This job is enqueued with the chat, user content, placeholder message ID, and optional focus
# 3. CptChatService performs RAG retrieval and starts LLM streaming
# 4. Each chunk is broadcast to the user via ActionCable in real-time
# 5. Final content is persisted to the placeholder message
#
# Focus Context:
# The optional focus_context hash allows prioritizing specific therapy items in the
# AI's response. Pass { type: 'stuck_point', id: 123 } to focus on that item.
# Supported types: index_event, stuck_point, abc_worksheet, alternative_thought, baseline
#
# Error Handling:
# All RubyLLM errors are caught and converted to user-friendly messages.
# The assistant message is always updated with either content or error message.
#
class ChatResponseJob < ApplicationJob
  queue_as :critical

  def perform(chat_id, content, assistant_message_id, focus_context = {})
    chat = Chat.find(chat_id)
    message = Message.find(assistant_message_id)
    user = chat.user
    accumulated_content = +'' # Mutable string for efficient concatenation

    # Build focus hash from serialized context (background jobs can't receive AR objects)
    focus = build_focus(focus_context)

    # CptChatService handles RAG retrieval, system prompt construction, and LLM interaction
    service = CptChatService.new(chat, user, focus: focus)
    service.ask(content) do |chunk|
      next if chunk.content.blank?

      accumulated_content << chunk.content
      # Broadcast each chunk for real-time UI streaming via ActionCable
      message.broadcast_append_chunk(chunk.content)
    end

    # Persist the complete response to the database
    message.update!(content: accumulated_content)

    # Broadcast the audio loading spinner now that content exists
    # This creates the target div that TextToSpeechJob will replace when audio is ready
    broadcast_audio_loading(message)

    # Queue TTS generation for the completed message
    TextToSpeechJob.perform_later(message.id)
  # Granular error handling provides specific feedback for different failure modes
  rescue RubyLLM::UnauthorizedError
    handle_error(message, 'API key is invalid or missing. Please check your configuration.',
                 'Sorry, I encountered an authentication error. Please contact support.')
  rescue RubyLLM::BadRequestError => e
    handle_error(message, "Request error: #{e.message}",
                 'Sorry, there was an issue with the request. Please try again.')
  rescue RubyLLM::RateLimitError
    handle_error(message, 'Rate limit exceeded. Please wait a moment and try again.',
                 'Sorry, we hit a rate limit. Please wait a moment and try again.')
  rescue RubyLLM::ServerError
    handle_error(message, 'The AI service is temporarily unavailable. Please try again later.',
                 'Sorry, the AI service is temporarily unavailable. Please try again later.')
  rescue StandardError => e
    Rails.logger.error("ChatResponseJob error: #{e.class} - #{e.message}")
    handle_error(message, 'An unexpected error occurred. Please try again.',
                 'Sorry, something went wrong. Please try again.')
  end

  private

  # Converts serialized focus context to ActiveRecord objects.
  # Background jobs receive primitive types, so we reconstruct the focus hash here.
  #
  # @param focus_context [Hash] Serialized context with :type and :id keys
  # @return [Hash] Focus hash with symbolized type key and AR object value
  def build_focus(focus_context)
    return {} if focus_context.blank?

    # Handle both string and symbol keys (job serialization may vary)
    type = focus_context[:type] || focus_context['type']
    id = focus_context[:id] || focus_context['id']

    return {} if type.blank? || id.blank?

    model_class = focus_type_to_class(type)
    return {} unless model_class

    record = model_class.find_by(id: id)
    return {} unless record

    { type.to_sym => record }
  end

  # Maps focus type strings to their corresponding model classes
  def focus_type_to_class(type)
    {
      'index_event' => IndexEvent,
      'stuck_point' => StuckPoint,
      'abc_worksheet' => AbcWorksheet,
      'alternative_thought' => AlternativeThought,
      'baseline' => Baseline
    }[type.to_s]
  end

  # Broadcasts error to UI and persists fallback content to the message
  def handle_error(message, broadcast_text, persist_text)
    message.broadcast_error(broadcast_text)
    message.update!(content: persist_text)
  end

  # Broadcasts the audio loading spinner to show TTS is processing.
  # The audio container div is always rendered in the template (empty initially).
  # This replaces it with the loading spinner, which TextToSpeechJob will then
  # replace with the audio player when ready.
  def broadcast_audio_loading(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{message.chat_id}",
      target: "message_#{message.id}_audio",
      partial: 'messages/audio_loading',
      locals: { message: message }
    )
  end
end
