# frozen_string_literal: true

# =============================================================================
# ChatsController - AI Chat Session Management
# =============================================================================
#
# Manages chat sessions for the AI therapist interface. Each user typically
# has one persistent chat that's reused across sessions (created automatically
# in ApplicationController).
#
# Actions:
# - create: Manually create a new chat (if needed)
# - clear: Wipe chat history while keeping the chat record
#
# The clear action uses a background job because chat histories can grow large
# and we don't want to block the user's request while deleting messages.
#
class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:clear]

  # Creates a new chat session with the default LLM model
  def create
    @chat = current_user.chats.create! do |chat|
      chat.model = Chat.find_or_create_default_model
    end
    redirect_to root_path
  end

  # Clears all messages from the chat history asynchronously.
  # The chat record itself is preserved so the user can continue chatting.
  def clear
    DeleteChatMessagesJob.perform_later(@chat.id)

    respond_to do |format|
      format.turbo_stream # Renders clear.turbo_stream.erb
      format.html { redirect_to root_path }
    end
  end

  private

  # Finds chat scoped to current user for authorization
  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
