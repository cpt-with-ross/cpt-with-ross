class ChatsController < ApplicationController
  before_action :set_chat, only: [:show]

  def index
    @chats = Chat.order(created_at: :desc)
  end

  def show
    if params[:challenge_id].present?
      @challenge = Challenge.find(params[:challenge_id])
      @chat = @challenge.chat
      @message = @chat.messages.build
      render :challenge_show
    else
      @chat = Chat.find(params[:id])
      @message = @chat.messages.build
    end
  end

  def new
    @chat = Chat.new
    @selected_model = params[:model]
  end

  def create
    return if prompt.blank?

    @chat = Chat.create!(model: model)
    ChatResponseJob.perform_later(@chat.id, prompt)

    redirect_to @chat, notice: 'Chat was successfully created.'
  end

  private

  def set_chat
    # Check if accessed via nested challenge route
    if params[:challenge_id].present?
      @challenge = Challenge.find(params[:challenge_id])
      @chat = @challenge.chat
    else
      # Regular chat show by ID
      @chat = Chat.find(params[:id])
    end
  end

  def model
    params[:chat][:model].presence
  end

  def prompt
    params[:chat][:prompt]
  end
end
