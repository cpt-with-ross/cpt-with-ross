# Shared controller helpers for resources nested under StuckPoint.
# Used by AbcWorksheetsController and AlternativeThoughtsController.
module StuckPointChildResource
  extend ActiveSupport::Concern

  included do
    include ActionView::RecordIdentifier

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :set_stuck_point, only: %i[new create]
    # rubocop:enable Rails/LexicallyScopedActionFilter
  end

  private

  def set_stuck_point
    @stuck_point = StuckPoint.joins(index_event: :user)
                             .where(users: { id: current_user.id })
                             .find(params[:stuck_point_id])
  end

  def destroy_with_fallback(resource, resource_path)
    index_event = @stuck_point.index_event
    viewing_self = params[:current_path] == resource_path
    resource.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(resource))]
        if viewing_self
          streams << turbo_stream.update('main_content',
                                         partial: 'impact_statements/impact_statement',
                                         locals: { impact_statement: index_event.impact_statement })
        end
        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end
end
