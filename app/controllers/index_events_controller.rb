class IndexEventsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event, only: %i[edit update destroy]

  def new
    @index_event = IndexEvent.new
    render_inline_form @index_event,
                       url: index_events_path,
                       placeholder: 'New Index Event Name...',
                       frame_id: 'new_index_event_form_frame',
                       attribute_name: :title
  end

  def edit
    render_inline_form @index_event,
                       url: index_event_path(@index_event),
                       placeholder: 'Index Event Name...',
                       frame_id: dom_id(@index_event, :title_frame),
                       attribute_name: :title
  end

  def create
    @index_event = IndexEvent.new(index_event_params)

    if @index_event.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append('indexEventsAccordion',
                              partial: 'index_events/sidebar_item',
                              locals: { index_event: @index_event }),
          turbo_stream.update('new_index_event_form_frame', '')
        ]
      end
    else
      render_inline_form @index_event,
                         url: index_events_path,
                         placeholder: 'New Index Event Name...',
                         frame_id: 'new_index_event_form_frame',
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  def update
    if @index_event.update(index_event_params)
      respond_with_turbo_or_redirect do
        render turbo_stream: turbo_stream.replace(
          dom_id(@index_event, :title_frame),
          partial: 'index_events/title_button',
          locals: { index_event: @index_event }
        )
      end
    else
      render_inline_form @index_event,
                         url: index_event_path(@index_event),
                         placeholder: 'Index Event Name...',
                         frame_id: dom_id(@index_event, :title_frame),
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  def destroy
    @index_event.destroy
    turbo_stream_remove(@index_event)
  end

  private

  def set_index_event
    @index_event = IndexEvent.find(params[:id])
  end

  def index_event_params
    params.require(:index_event).permit(:title)
  end
end
