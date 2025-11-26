class ChatsController < ApplicationController
  before_action :set_challenge

  def show
    @chat = current_user.chats.find_or_create_by(challenge: @challenge)
    context = "I am working on a challenge titled '#{@challenge.title}'. #{@challenge.description}"
    @chat.messages.create(role: 'system', content: context)
    @message = Message.new
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end
end
