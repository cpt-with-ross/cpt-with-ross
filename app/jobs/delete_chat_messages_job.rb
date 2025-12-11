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

    message_ids = chat.message_ids

    # Purge audio attachments (deletes file, blob record, and attachment record)
    audio_attachments = ActiveStorage::Attachment.includes(:blob)
                                                 .where(record_type: 'Message', record_id: message_ids, name: 'audio')
    audio_count = audio_attachments.size
    audio_attachments.each(&:purge)

    if audio_count.positive?
      Rails.logger.info("DeleteChatMessagesJob: Purged #{audio_count} audio files from Chat##{chat_id}")
      cleanup_empty_storage_directories
    end

    # Delete messages (fast bulk operation)
    deleted_count = chat.messages.delete_all
    Rails.logger.info("DeleteChatMessagesJob: Deleted #{deleted_count} messages from Chat##{chat_id}")
  end

  private

  # ActiveStorage Disk service leaves empty directories after purging files.
  # This cleans up empty nested directories in the storage path.
  def cleanup_empty_storage_directories
    return unless ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)

    storage_root = ActiveStorage::Blob.service.root

    # Find and remove empty directories (deepest first)
    Dir.glob(File.join(storage_root, '**', '*'))
       .select { |d| File.directory?(d) }
       .sort_by { |d| -d.count(File::SEPARATOR) } # Deepest first
       .each do |dir|
         Dir.rmdir(dir) if Dir.empty?(dir)
       rescue Errno::ENOTEMPTY, Errno::ENOENT
         # Directory not empty or already removed - skip
       end
  end
end
