# rubocop:disable Metrics/ClassLength
class StuckPointsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event, only: %i[new create]
  before_action :set_stuck_point, only: %i[show edit update destroy]

  def show
    render partial: 'stuck_points/title_button',
           locals: { stuck_point: @stuck_point },
           layout: false
  end

  def new
    @stuck_point = @index_event.stuck_points.build
    render_inline_form @stuck_point,
                       url: index_event_stuck_points_path(@index_event),
                       placeholder: 'New Stuck Point...',
                       frame_id: "new_stuck_point_frame_#{@index_event.id}",
                       attribute_name: :statement
  end

  def edit
    render_inline_form @stuck_point,
                       url: stuck_point_path(@stuck_point),
                       placeholder: 'Stuck Point Name...',
                       frame_id: dom_id(@stuck_point, :title_frame),
                       attribute_name: :statement,
                       cancel_url: stuck_point_path(@stuck_point)
  end

  def create
    @stuck_point = @index_event.stuck_points.build(stuck_point_params)

    if @stuck_point.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append("stuck_points_list_#{@index_event.id}",
                              partial: 'stuck_points/sidebar_item',
                              locals: { stuck_point: @stuck_point }),
          turbo_stream.update("new_stuck_point_frame_#{@index_event.id}", '')
        ]
      end
    else
      render_inline_form @stuck_point,
                         url: index_event_stuck_points_path(@index_event),
                         placeholder: 'New Stuck Point...',
                         frame_id: "new_stuck_point_frame_#{@index_event.id}",
                         attribute_name: :statement,
                         status: :unprocessable_content
    end
  end

  def update
    if @stuck_point.update(stuck_point_params)
      # Update beliefs on all ABC worksheets when statement changes
      @stuck_point.abc_worksheets.find_each { |ws| ws.update(beliefs: @stuck_point.statement) }

      respond_with_turbo_or_redirect do
        streams = [
          turbo_stream.replace(
            dom_id(@stuck_point, :title_frame),
            partial: 'stuck_points/title_button',
            locals: { stuck_point: @stuck_point }
          )
        ]

        # Refresh center column if viewing a child to update the header and content
        child_content = find_viewed_child_content
        streams << turbo_stream.update('main_content', child_content) if child_content

        render turbo_stream: streams
      end
    else
      render_inline_form @stuck_point,
                         url: stuck_point_path(@stuck_point),
                         placeholder: 'Stuck Point Name...',
                         frame_id: dom_id(@stuck_point, :title_frame),
                         attribute_name: :statement,
                         cancel_url: stuck_point_path(@stuck_point),
                         status: :unprocessable_content
    end
  end

  def destroy
    index_event = @stuck_point.index_event
    child_paths = build_child_paths(@stuck_point)
    @stuck_point.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(@stuck_point))]

        if viewing_child?(child_paths)
          streams << turbo_stream.update('main_content',
                                         partial: 'impact_statements/impact_statement',
                                         locals: { impact_statement: index_event.impact_statement })
        end

        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end

  private

  def set_index_event
    @index_event = current_user.index_events.find(params[:index_event_id])
  end

  def set_stuck_point
    @stuck_point = StuckPoint.find(params[:id])
  end

  def stuck_point_params
    params.require(:stuck_point).permit(:statement, :belief, :belief_type, :resolved)
  end

  def build_child_paths(stuck_point)
    stuck_point.abc_worksheets.map { |ws| abc_worksheet_path(ws) } +
      stuck_point.alternative_thoughts.map { |at| alternative_thought_path(at) }
  end

  def viewing_child?(child_paths)
    current_path = params[:current_path]
    return false if current_path.blank?

    child_paths.include?(current_path)
  end

  def find_viewed_child_content
    current_path = params[:current_path]
    return nil if current_path.blank?

    # Reload associations to get fresh data after updates
    @stuck_point.abc_worksheets.reload.each do |ws|
      if current_path == abc_worksheet_path(ws)
        return render_to_string(partial: 'abc_worksheets/show_content',
                                locals: { abc_worksheet: ws, stuck_point: @stuck_point })
      end
    end

    @stuck_point.alternative_thoughts.reload.each do |at|
      if current_path == alternative_thought_path(at)
        return render_to_string(partial: 'alternative_thoughts/show_content',
                                locals: { alternative_thought: at, stuck_point: @stuck_point })
      end
    end

    nil
  end
end
# rubocop:enable Metrics/ClassLength
