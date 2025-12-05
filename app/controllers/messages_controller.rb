# frozen_string_literal: true

# =============================================================================
# MessagesController - Chat Message Creation and AI Response Triggering
# =============================================================================
#
# Handles the creation of chat messages and orchestrates AI response generation.
#
# Flow:
# 1. User submits a message via the chat form
# 2. Controller creates the user message record
# 3. Controller creates an empty placeholder for the assistant response
# 4. ChatResponseJob is enqueued to stream the AI response
# 5. Turbo Stream template renders both messages immediately (assistant shows loading)
# 6. ChatResponseJob streams content via ActionCable as it's generated
#
# The "placeholder then stream" pattern provides immediate UI feedback while
# the AI generates its response in the background.
#
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat

  # Creates a user message and triggers AI response generation.
  # Both user and (placeholder) assistant messages are created synchronously,
  # while the actual AI response is streamed asynchronously via background job.
  def create
    user_content = message_params[:content]
    return head :unprocessable_content if user_content.blank?

    # Persist the user's message
    @user_message = @chat.messages.create!(role: 'user', content: user_content)

    # Create empty assistant message - will be populated via streaming
    @assistant_message = @chat.messages.create!(role: 'assistant', content: '')

    # Start AI response generation in background (streams via ActionCable)
    ChatResponseJob.perform_later(@chat.id, user_content, @assistant_message.id)

    respond_to do |format|
      format.turbo_stream # Renders create.turbo_stream.erb
      format.html { redirect_to root_path }
    end
  end

  private

  # Finds chat scoped to current user for authorization
  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
