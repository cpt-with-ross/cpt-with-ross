# frozen_string_literal: true

# =============================================================================
# ApplicationController - Base Controller with Global Setup
# =============================================================================
#
# All controllers inherit from this class. It handles:
# 1. Authentication: Enforces Devise login for all actions
# 2. Sidebar data: Pre-loads the CPT hierarchy for the navigation sidebar
# 3. Chat setup: Ensures each user has a chat instance for AI interactions
# 4. Focus context: Tracks what therapy item the user is currently viewing
#
# The sidebar data is loaded on every request because the app uses a
# persistent sidebar layout. Eager loading prevents N+1 queries.
#
# Focus Context:
# Controllers can set @focus_context to indicate what the user is viewing.
# This context is passed to the AI chat to provide more relevant responses.
# Example: set_focus_context(:stuck_point, @stuck_point.id)
#
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_sidebar_data
  before_action :set_chat
  before_action :initialize_focus_context

  # Expose focus_context to views for rendering hidden form fields
  helper_method :focus_context

  private

  # Eager-loads the full CPT hierarchy for sidebar navigation.
  # The sidebar displays: IndexEvents > StuckPoints > [Worksheets, Thoughts]
  # This single query loads all nested data to prevent N+1s during rendering.
  def set_sidebar_data
    return unless current_user

    @index_events = current_user.index_events
                                .includes(stuck_points: %i[abc_worksheets alternative_thoughts])
                                .order(created_at: :desc)
  end

  # Ensures the current user has a Chat record for AI interactions.
  # Uses first_or_create to lazily initialize on first visit.
  # The chat is reused across sessions (not per-session).
  def set_chat
    return unless current_user

    @chat = current_user.chats.first_or_create! do |chat|
      chat.model = Chat.find_or_create_default_model
    end
  end

  # Initialize empty focus context. Controllers override this via set_focus_context.
  def initialize_focus_context
    @focus_context = {}
  end

  # Sets the focus context for the current page.
  # This tells the AI chat what therapy item the user is currently viewing.
  #
  # @param type [Symbol] One of: :index_event, :stuck_point, :abc_worksheet,
  #                      :alternative_thought, :baseline
  # @param id [Integer] The ID of the focused record
  def set_focus_context(type, id)
    @focus_context = { type: type.to_s, id: id }
  end

  # Returns the current focus context hash for use in views
  def focus_context
    @focus_context || {}
  end
end
