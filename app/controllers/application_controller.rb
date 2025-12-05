class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_sidebar_data
  before_action :set_chat

  private

  # Eager-loads the full CPT hierarchy for sidebar navigation.
  # Prevents N+1 queries when rendering nested stuck_points and their worksheets.
  def set_sidebar_data
    return unless current_user

    @index_events = current_user.index_events
                                .includes(stuck_points: %i[abc_worksheets alternative_thoughts])
                                .order(created_at: :desc)
  end

  def set_chat
    return unless current_user

    @chat = current_user.chats.first_or_create! do |chat|
      chat.model = Chat.find_or_create_default_model
    end
  end
end
