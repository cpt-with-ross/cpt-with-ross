# RubyLLM gem integration for AI message handling.
# acts_as_message provides: #role, #content, #tool_calls, and token tracking.
class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_many_attached :attachments

  # Broadcasts full message updates to subscribers of this chat's ActionCable channel.
  broadcasts_to ->(message) { "chat_#{message.chat_id}" }

  # Streams individual LLM response chunks to the UI in real-time.
  # Called by ChatResponseJob as the AI generates each token.
  # Target must match the DOM element ID in messages/_message.html.erb.
  def broadcast_append_chunk(content)
    broadcast_append_to "chat_#{chat_id}",
                        target: "message_#{id}_content",
                        partial: 'messages/content',
                        locals: { content: content }
  end
end
