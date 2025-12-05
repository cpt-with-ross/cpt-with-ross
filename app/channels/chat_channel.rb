# ActionCable channel for real-time chat message streaming.
# Subscribes to chat-specific broadcasts from Message model.
class ChatChannel < ApplicationCable::Channel
  def subscribed
    @chat = Chat.find(params[:chat_id])
    stream_from "chat_#{@chat.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
