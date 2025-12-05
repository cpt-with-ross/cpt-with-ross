class StuckPointsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event, only: %i[new create]
  before_action :set_stuck_point, only: %i[edit update destroy]

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
                       attribute_name: :statement
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
      respond_with_turbo_or_redirect do
        render turbo_stream: turbo_stream.replace(
          dom_id(@stuck_point, :title_frame),
          partial: 'stuck_points/title_button',
          locals: { stuck_point: @stuck_point }
        )
      end
    else
      render_inline_form @stuck_point,
                         url: stuck_point_path(@stuck_point),
                         placeholder: 'Stuck Point Name...',
                         frame_id: dom_id(@stuck_point, :title_frame),
                         attribute_name: :statement,
                         status: :unprocessable_content
    end
  end

  def destroy
    @stuck_point.destroy
    turbo_stream_remove(@stuck_point)
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
end
