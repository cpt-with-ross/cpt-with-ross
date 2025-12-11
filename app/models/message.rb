# frozen_string_literal: true

# =============================================================================
# Message - Chat Message Record with ActionCable Broadcasting
# =============================================================================
#
# Represents a single message in an AI chat conversation. Uses RubyLLM's
# acts_as_message pattern which provides role, content, and tool_call tracking.
#
# Roles:
# - user: Messages from the human user
# - assistant: Responses from the AI (Ross)
# - system: System prompts (generated per-request, not persisted)
#
# Real-Time Streaming:
# The broadcast_* methods enable real-time UI updates via ActionCable.
# As ChatResponseJob receives streaming chunks from the LLM, it calls
# broadcast_append_chunk to push each chunk to the user's browser.
#
class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_many_attached :attachments
  has_one_attached :audio

  # Streams a chunk of LLM response to the UI in real-time.
  # Called repeatedly by ChatResponseJob as each token is generated.
  # Uses Turbo Streams to append content to the message's content container.
  def broadcast_append_chunk(content)
    broadcast_append_to "chat_#{chat_id}",
                        target: "message_#{id}_content",
                        partial: 'messages/content',
                        locals: { content: content }
  end

  # Replaces the message content with an error message.
  # Used when LLM API calls fail after the placeholder was already rendered.
  def broadcast_error(error_message)
    broadcast_replace_to "chat_#{chat_id}",
                         target: "message_#{id}_content",
                         partial: 'messages/error',
                         locals: { error_message: error_message }
  end

  # =============================================================================
  # TTS Audio Helpers
  # =============================================================================

  # Returns true if this is an assistant message that should have TTS
  def tts_eligible?
    role == 'assistant' && content.present?
  end

  # Returns true if TTS audio is ready to play
  def tts_ready?
    tts_eligible? && audio.attached?
  end

  # Returns true if TTS is still processing (job queued or running)
  def tts_processing?
    tts_eligible? && !audio.attached?
  end

  # Returns the audio URL for playback (nil if not ready)
  def audio_url
    return nil unless tts_ready?

    Rails.application.routes.url_helpers.rails_blob_path(
      audio,
      only_path: true,
      disposition: 'inline'
    )
  end
end
