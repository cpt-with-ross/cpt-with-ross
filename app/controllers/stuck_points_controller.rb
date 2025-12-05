# frozen_string_literal: true

# =============================================================================
# StuckPointsController - Managing Cognitive Stuck Points
# =============================================================================
#
# A "Stuck Point" in CPT is a negative or unhelpful thought/belief that keeps
# someone "stuck" in unhelpful patterns after trauma. Examples:
# - "I should have prevented what happened"
# - "The world is completely dangerous"
# - "I can't trust anyone"
#
# Stuck Points are the focus of CPT therapy work. Users create them, then work
# through them via ABC Worksheets (identifying patterns) and Alternative
# Thoughts (developing balanced perspectives).
#
# This controller follows the same inline-editing and Turbo Stream patterns
# as IndexEventsController. Key addition: When a stuck point's statement is
# updated, we trigger an async job to sync the statement to all related ABC
# worksheets (which display the stuck point as their "B - Belief" field).
#
# rubocop:disable Metrics/ClassLength
class StuckPointsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event, only: %i[new create]
  before_action :set_stuck_point, only: %i[show edit update destroy]

  # Returns title button partial for Turbo Frame refresh
  def show
    render partial: 'stuck_points/title_button',
           locals: { stuck_point: @stuck_point },
           layout: false
  end

  # Renders inline form for new stuck point within an IndexEvent's accordion
  def new
    @stuck_point = @index_event.stuck_points.build
    render_inline_form @stuck_point,
                       url: index_event_stuck_points_path(@index_event),
                       placeholder: 'New Stuck Point...',
                       frame_id: "new_stuck_point_frame_#{@index_event.id}",
                       attribute_name: :statement
  end

  # Renders inline form for editing existing stuck point statement
  def edit
    render_inline_form @stuck_point,
                       url: stuck_point_path(@stuck_point),
                       placeholder: 'Stuck Point Name...',
                       frame_id: dom_id(@stuck_point, :title_frame),
                       attribute_name: :statement,
                       cancel_url: stuck_point_path(@stuck_point)
  end

  # Creates new stuck point nested under an IndexEvent.
  # Adds to the sidebar list within the parent event's accordion section.
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

  # Updates stuck point. When the statement changes, queues a background job
  # to sync the new statement to all ABC worksheets (their "beliefs" field
  # should match the stuck point statement).
  def update
    if @stuck_point.update(stuck_point_params)
      # Async sync: Update all ABC worksheet beliefs to match new statement
      UpdateAbcBeliefsJob.perform_later(@stuck_point.id, @stuck_point.statement)

      respond_with_turbo_or_redirect do
        streams = [
          turbo_stream.replace(
            dom_id(@stuck_point, :title_frame),
            partial: 'stuck_points/title_button',
            locals: { stuck_point: @stuck_point }
          )
        ]

        # Refresh main content if viewing a child resource (worksheet/thought)
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

  # Deletes stuck point and all children (cascade via dependent: :destroy).
  # If user was viewing a child, shows impact statement as fallback.
  def destroy
    index_event = @stuck_point.index_event
    child_paths = build_child_paths(@stuck_point)
    @stuck_point.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(@stuck_point))]

        # If viewing deleted child content, show impact statement instead
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

  # Finds parent IndexEvent scoped to current user
  def set_index_event
    @index_event = current_user.index_events.find(params[:index_event_id])
  end

  # Finds stuck point by ID (shallow route)
  def set_stuck_point
    @stuck_point = StuckPoint.find(params[:id])
  end

  def stuck_point_params
    params.require(:stuck_point).permit(:statement, :belief, :belief_type, :resolved)
  end

  # Builds list of URL paths to child resources for deletion fallback logic
  def build_child_paths(stuck_point)
    stuck_point.abc_worksheets.map { |ws| abc_worksheet_path(ws) } +
      stuck_point.alternative_thoughts.map { |at| alternative_thought_path(at) }
  end

  # Checks if user is currently viewing one of this stuck point's children
  def viewing_child?(child_paths)
    current_path = params[:current_path]
    return false if current_path.blank?

    child_paths.include?(current_path)
  end

  # Finds and renders the content for whatever child the user is viewing.
  # Reloads associations to get fresh data after any updates.
  def find_viewed_child_content
    current_path = params[:current_path]
    return nil if current_path.blank?

    # Check if viewing an ABC worksheet
    @stuck_point.abc_worksheets.reload.each do |ws|
      if current_path == abc_worksheet_path(ws)
        return render_to_string(partial: 'abc_worksheets/show_content',
                                locals: { abc_worksheet: ws, stuck_point: @stuck_point })
      end
    end

    # Check if viewing an alternative thought
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
