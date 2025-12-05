class IndexEventsController < ApplicationController
  include InlineFormRenderable

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
    current_path = params[:current_path]
    Rails.logger.info "DELETE INDEX EVENT - current_path: '#{current_path}'"
    Rails.logger.info "DELETE INDEX EVENT - related_paths: #{related_paths}"
    Rails.logger.info "DELETE INDEX EVENT - match?: #{related_paths.include?(current_path)}"
    @index_event.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(@index_event))]

        if viewing_related_content?(related_paths)
          Rails.logger.info 'DELETE INDEX EVENT - Updating main_content to welcome'
          streams << turbo_stream.update('main_content', partial: 'dashboard/welcome')
        else
          Rails.logger.info 'DELETE INDEX EVENT - NOT updating main_content'
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

  def build_related_paths(index_event)
    paths = [index_event_impact_statement_path(index_event)]

    index_event.stuck_points.each do |sp|
      sp.abc_worksheets.each { |ws| paths << abc_worksheet_path(ws) }
      sp.alternative_thoughts.each { |at| paths << alternative_thought_path(at) }
    end

    paths
  end

  def viewing_related_content?(related_paths)
    current_path = params[:current_path]
    return false if current_path.blank?

    related_paths.include?(current_path)
  end

  def find_viewed_child_content
    current_path = params[:current_path]
    return nil if current_path.blank?

    # Check if viewing impact statement
    if current_path == index_event_impact_statement_path(@index_event)
      return render_to_string(partial: 'impact_statements/show_content',
                              locals: { impact_statement: @index_event.impact_statement,
                                        index_event: @index_event })
    end

    # Check ABC worksheets
    @index_event.stuck_points.each do |sp|
      sp.abc_worksheets.each do |ws|
        if current_path == abc_worksheet_path(ws)
          return render_to_string(partial: 'abc_worksheets/show_content',
                                  locals: { abc_worksheet: ws, stuck_point: sp })
        end
      end

      sp.alternative_thoughts.each do |at|
        if current_path == alternative_thought_path(at)
          return render_to_string(partial: 'alternative_thoughts/show_content',
                                  locals: { alternative_thought: at, stuck_point: sp })
        end
      end
    end

    nil
  end
end
