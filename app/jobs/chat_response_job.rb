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
# 2. This job is enqueued with the chat, user content, and placeholder message ID
# 3. CptChatService performs RAG retrieval and starts LLM streaming
# 4. Each chunk is broadcast to the user via ActionCable in real-time
# 5. Final content is persisted to the placeholder message
#
# Error Handling:
# All RubyLLM errors are caught and converted to user-friendly messages.
# The assistant message is always updated with either content or error message.
#
class ChatResponseJob < ApplicationJob
  queue_as :critical

  def perform(chat_id, content, assistant_message_id)
    chat = Chat.find(chat_id)
    message = Message.find(assistant_message_id)
    user = chat.user
    accumulated_content = +'' # Mutable string for efficient concatenation

    # CptChatService handles RAG retrieval, system prompt construction, and LLM interaction
    service = CptChatService.new(chat, user)
    service.ask(content) do |chunk|
      next if chunk.content.blank?

      accumulated_content << chunk.content
      # Broadcast each chunk for real-time UI streaming via ActionCable
      message.broadcast_append_chunk(chunk.content)
    end

    # Persist the complete response to the database
    message.update!(content: accumulated_content)

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

  # Broadcasts error to UI and persists fallback content to the message
  def handle_error(message, broadcast_text, persist_text)
    message.broadcast_error(broadcast_text)
    message.update!(content: persist_text)
  end
end
