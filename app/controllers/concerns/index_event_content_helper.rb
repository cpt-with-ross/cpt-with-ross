# frozen_string_literal: true

# =============================================================================
# IndexEventContentHelper - Content Path Tracking for Index Event Updates
# =============================================================================
#
# This concern handles a complex UX scenario when updating an IndexEvent:
# The app uses a sidebar navigation pattern where clicking an item loads its
# content into the main_content frame. When an IndexEvent is updated, we need
# to check if the user is currently viewing any of its child content (impact
# statement, worksheets, alternative thoughts) and preserve that view.
#
# The Problem:
# When updating an IndexEvent via Turbo Stream, the sidebar re-renders with
# new data. If the user is viewing a child resource, we need to refresh that
# content too (in case its parent data changed) or at minimum not break the UI.
#
# The Solution:
# 1. Build list of all paths to related content (build_related_paths)
# 2. Check if current_path (tracked via Stimulus) matches any of them
# 3. Re-render the appropriate partial if viewing related content
#
module IndexEventContentHelper
  extend ActiveSupport::Concern

  private

  # Builds a list of all URL paths for content nested under this IndexEvent.
  # Used to determine if the user is currently viewing something that would
  # be affected by an IndexEvent update.
  def build_related_paths(index_event)
    paths = [index_event_impact_statement_path(index_event)]

    index_event.stuck_points.each do |sp|
      sp.abc_worksheets.each { |ws| paths << abc_worksheet_path(ws) }
      sp.alternative_thoughts.each { |at| paths << alternative_thought_path(at) }
    end

    paths
  end

  # Checks if the user's current view (tracked via current_path param) is
  # part of this IndexEvent's content tree.
  def viewing_related_content?(related_paths)
    current_path = params[:current_path]
    return false if current_path.blank?

    related_paths.include?(current_path)
  end

  # Finds and renders the content partial for whatever the user is currently
  # viewing. Returns nil if not viewing any related content.
  def find_viewed_child_content
    current_path = params[:current_path]
    return nil if current_path.blank?

    find_impact_statement_content(current_path) ||
      find_stuck_point_child_content(current_path)
  end

  # Renders impact statement partial if user is viewing the impact statement
  def find_impact_statement_content(current_path)
    return unless current_path == index_event_impact_statement_path(@index_event)

    render_to_string(partial: 'impact_statements/show_content',
                     locals: { impact_statement: @index_event.impact_statement,
                               index_event: @index_event })
  end

  # Searches through all stuck points to find if user is viewing any of their
  # child resources (ABC worksheets or alternative thoughts)
  def find_stuck_point_child_content(current_path)
    @index_event.stuck_points.each do |sp|
      content = find_abc_worksheet_content(sp, current_path) ||
                find_alternative_thought_content(sp, current_path)
      return content if content
    end

    nil
  end

  # Renders ABC worksheet partial if user is viewing one of this stuck point's worksheets
  def find_abc_worksheet_content(stuck_point, current_path)
    stuck_point.abc_worksheets.each do |ws|
      next unless current_path == abc_worksheet_path(ws)

      return render_to_string(partial: 'abc_worksheets/show_content',
                              locals: { abc_worksheet: ws, stuck_point: stuck_point })
    end

    nil
  end

  # Renders alternative thought partial if user is viewing one of this stuck point's thoughts
  def find_alternative_thought_content(stuck_point, current_path)
    stuck_point.alternative_thoughts.each do |at|
      next unless current_path == alternative_thought_path(at)

      return render_to_string(partial: 'alternative_thoughts/show_content',
                              locals: { alternative_thought: at, stuck_point: stuck_point })
    end

    nil
  end
end
