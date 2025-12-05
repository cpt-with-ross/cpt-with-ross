# frozen_string_literal: true

# =============================================================================
# ChatChannel - Real-Time AI Response Streaming via ActionCable
# =============================================================================
#
# This channel enables real-time streaming of AI responses from ChatResponseJob
# to the user's browser. When a user subscribes, they receive broadcasts for
# their specific chat.
#
# Flow:
# 1. User loads chat UI -> JavaScript subscribes to ChatChannel with chat_id
# 2. User sends message -> MessagesController enqueues ChatResponseJob
# 3. ChatResponseJob calls message.broadcast_append_chunk() for each token
# 4. This channel streams the broadcast to the subscribed client
# 5. Turbo Streams updates the DOM with the new content
#
# Security:
# - Connection is authenticated via ApplicationCable::Connection (Devise/Warden)
# - Each subscription is scoped to a specific chat_id
#
class ChatChannel < ApplicationCable::Channel
  # Called when client subscribes. Validates chat exists and streams updates.
  def subscribed
    @chat = Chat.find(params[:chat_id])
    stream_from "chat_#{@chat.id}"
  end

  # Called when client disconnects or navigates away
  def unsubscribed
    stop_all_streams
  end
end
