# Handles chat message creation and triggers AI response generation.
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat

  def create
    user_content = message_params[:content]
    return head :unprocessable_content if user_content.blank?

    # Create user message
    @user_message = @chat.messages.create!(role: 'user', content: user_content)

    # Create placeholder assistant message for streaming
    @assistant_message = @chat.messages.create!(role: 'assistant', content: '')

    # Enqueue background job to stream AI response
    ChatResponseJob.perform_later(@chat.id, user_content, @assistant_message.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
