# frozen_string_literal: true

# =============================================================================
# DeleteChatMessagesJob - Asynchronous Chat History Cleanup
# =============================================================================
#
# Deletes all messages for a given chat in the background. This is used when
# users want to "clear" their chat history without deleting the chat itself.
#
# Why async? Chat histories can grow large (hundreds of messages), and we
# don't want to block the user's request while performing bulk deletions.
#
# Note: Uses delete_all (not destroy_all) for performance - message callbacks
# are not needed for cleanup operations.
#
class DeleteChatMessagesJob < ApplicationJob
  queue_as :background

  def perform(chat_id)
    chat = Chat.find_by(id: chat_id)
    return unless chat # Gracefully handle if chat was deleted before job runs

    deleted_count = chat.messages.delete_all

    Rails.logger.info("DeleteChatMessagesJob: Deleted #{deleted_count} messages from Chat##{chat_id}")
  end
end
