class MessagesController < ApplicationController
  before_action :set_chat

  def create
    return if content.blank?

    ChatResponseJob.perform_later(@chat.id, content)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('new_message', partial: 'messages/form',
                                                                 locals: { chat: @chat, message: Message.new })
      end
      format.html { redirect_to challenge_chat_path(@chat.challenge) }
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def content
    params[:message][:content]
  end
end
