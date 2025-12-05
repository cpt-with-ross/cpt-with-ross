# Background job for deleting chat messages asynchronously.
# Handles large chat histories without blocking the request.
class DeleteChatMessagesJob < ApplicationJob
  queue_as :background

  def perform(chat_id)
    chat = Chat.find_by(id: chat_id)
    return unless chat

    deleted_count = chat.messages.delete_all

    Rails.logger.info("DeleteChatMessagesJob: Deleted #{deleted_count} messages from Chat##{chat_id}")
  end
end
