# Handles chat creation and management for users.
class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:clear]

  def create
    @chat = current_user.chats.create! do |chat|
      chat.model = Chat.find_or_create_default_model
    end
    redirect_to root_path
  end

  def clear
    # Delete messages asynchronously for large chat histories
    DeleteChatMessagesJob.perform_later(@chat.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
