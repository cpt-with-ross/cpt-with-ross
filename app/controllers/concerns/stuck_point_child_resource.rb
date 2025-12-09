# frozen_string_literal: true

# =============================================================================
# StuckPointChildResource - Shared Logic for StuckPoint Nested Resources
# =============================================================================
#
# This concern extracts common controller patterns for resources that belong
# to a StuckPoint (AbcWorksheets and AlternativeThoughts). Both share:
#
# 1. Parent lookup: Finding the stuck_point via nested route params
# 2. Authorization: Ensuring the stuck_point belongs to the current user
# 3. Deletion UX: Smart fallback when deleting the currently-viewed item
#
# The "destroy_with_fallback" pattern handles an edge case in the SPA-like UI:
# If the user deletes an item they're currently viewing in the main content
# area, we need to replace that content with something sensible (the baseline)
# rather than leaving a blank space.
#
module StuckPointChildResource
  extend ActiveSupport::Concern

  included do
    include ActionView::RecordIdentifier

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :set_stuck_point, only: %i[new create]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  private

  # Finds the parent StuckPoint from nested route params with authorization.
  # Uses a join to ensure the stuck point belongs to the current user's data.
  def set_stuck_point
    @stuck_point = StuckPoint.joins(index_event: :user)
                             .where(users: { id: current_user.id })
                             .find(params[:stuck_point_id])
  end

  # Checks if the user is currently viewing the given resource path.
  # Used to determine whether main_content should be updated on sidebar rename.
  def viewing_self?(resource_path)
    params[:current_path] == resource_path
  end

  # Deletes a resource and handles the edge case where the user is viewing
  # the item they just deleted. In that case, replaces the main content with
  # the baseline as a sensible fallback.
  #
  # The current_path param is sent via the delete_with_context controller
  # which reads from sessionStorage to know what content the user is viewing.
  def destroy_with_fallback(resource, resource_path)
    index_event = @stuck_point.index_event
    viewing_self = viewing_self?(resource_path)
    resource.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(resource))]
        # If user was viewing the deleted item, show baseline instead
        if viewing_self
          streams << turbo_stream.update('main_content',
                                         partial: 'baselines/show_content',
                                         locals: { baseline: index_event.baseline,
                                                   index_event: index_event })
        end
        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end
end
