class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_sidebar_data

  private

  # Eager-loads the full CPT hierarchy for sidebar navigation.
  # Prevents N+1 queries when rendering nested stuck_points and their worksheets.
  def set_sidebar_data
    @index_events = IndexEvent
                    .includes(stuck_points: %i[abc_worksheets alternative_thoughts])
                    .order(created_at: :desc)
  end
end
