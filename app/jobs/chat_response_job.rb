# Background job for streaming LLM responses to the UI in real-time.
# Uses CptChatService for RAG retrieval and RubyLLM streaming.
class ChatResponseJob < ApplicationJob
  queue_as :critical

  def perform(chat_id, content, assistant_message_id)
    chat = Chat.find(chat_id)
    message = Message.find(assistant_message_id)
    user = chat.user
    accumulated_content = +''

    # Use CptChatService for dynamic RAG retrieval and streaming
    service = CptChatService.new(chat, user)
    service.ask(content) do |chunk|
      next if chunk.content.blank?

      accumulated_content << chunk.content
      message.broadcast_append_chunk(chunk.content)
    end

    # Update the message with final content
    message.update!(content: accumulated_content)
  rescue RubyLLM::UnauthorizedError
    message.broadcast_error('API key is invalid or missing. Please check your configuration.')
    message.update!(content: 'Sorry, I encountered an authentication error. Please contact support.')
  rescue RubyLLM::BadRequestError => e
    message.broadcast_error("Request error: #{e.message}")
    message.update!(content: 'Sorry, there was an issue with the request. Please try again.')
  rescue RubyLLM::RateLimitError
    message.broadcast_error('Rate limit exceeded. Please wait a moment and try again.')
    message.update!(content: 'Sorry, we hit a rate limit. Please wait a moment and try again.')
  rescue RubyLLM::ServerError
    message.broadcast_error('The AI service is temporarily unavailable. Please try again later.')
    message.update!(content: 'Sorry, the AI service is temporarily unavailable. Please try again later.')
  rescue StandardError => e
    Rails.logger.error("ChatResponseJob error: #{e.class} - #{e.message}")
    message.broadcast_error('An unexpected error occurred. Please try again.')
    message.update!(content: 'Sorry, something went wrong. Please try again.')
  end
end
