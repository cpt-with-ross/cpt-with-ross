class IndexEventsController < ApplicationController
  include InlineFormRenderable
  include IndexEventContentHelper

  before_action :set_index_event, only: %i[show edit update destroy]

  def show
    render partial: 'index_events/title_button',
           locals: { index_event: @index_event, is_active: false },
           layout: false
  end

  def new
    @index_event = current_user.index_events.build
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
                       attribute_name: :title,
                       cancel_url: index_event_path(@index_event)
  end

  def create
    @index_event = current_user.index_events.build(index_event_params)

    if @index_event.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append('indexEventsAccordion',
                              partial: 'index_events/sidebar_item',
                              locals: { index_event: @index_event, is_active: false }),
          turbo_stream.update('new_index_event_form_frame', ''),
          turbo_stream.update('main_content',
                              partial: 'impact_statements/show_content',
                              locals: { impact_statement: @index_event.impact_statement,
                                        index_event: @index_event })
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
        streams = [
          turbo_stream.replace(
            dom_id(@index_event, :title_frame),
            partial: 'index_events/title_button',
            locals: { index_event: @index_event, is_active: false }
          )
        ]

        # Refresh center column if viewing related content to update the header
        child_content = find_viewed_child_content
        streams << turbo_stream.update('main_content', child_content) if child_content

        render turbo_stream: streams
      end
    else
      render_inline_form @index_event,
                         url: index_event_path(@index_event),
                         placeholder: 'Index Event Name...',
                         frame_id: dom_id(@index_event, :title_frame),
                         attribute_name: :title,
                         cancel_url: index_event_path(@index_event),
                         status: :unprocessable_content
    end
  end

  def destroy
    related_paths = build_related_paths(@index_event)
    @index_event.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(@index_event))]
        if viewing_related_content?(related_paths)
          streams << turbo_stream.update('main_content', partial: 'dashboard/welcome')
        end
        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end

  private

  def set_index_event
    @index_event = current_user.index_events.find(params[:id])
  end

  def index_event_params
    params.require(:index_event).permit(:title)
  end
end
