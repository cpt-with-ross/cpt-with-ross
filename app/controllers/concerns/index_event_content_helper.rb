# Helper methods for IndexEventsController to manage content path tracking.
# Extracts complex path-building and content-finding logic.
module IndexEventContentHelper
  extend ActiveSupport::Concern

  private

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

    find_impact_statement_content(current_path) ||
      find_stuck_point_child_content(current_path)
  end

  def find_impact_statement_content(current_path)
    return unless current_path == index_event_impact_statement_path(@index_event)

    render_to_string(partial: 'impact_statements/show_content',
                     locals: { impact_statement: @index_event.impact_statement,
                               index_event: @index_event })
  end

  def find_stuck_point_child_content(current_path)
    @index_event.stuck_points.each do |sp|
      content = find_abc_worksheet_content(sp, current_path) ||
                find_alternative_thought_content(sp, current_path)
      return content if content
    end

    nil
  end

  def find_abc_worksheet_content(stuck_point, current_path)
    stuck_point.abc_worksheets.each do |ws|
      next unless current_path == abc_worksheet_path(ws)

      return render_to_string(partial: 'abc_worksheets/show_content',
                              locals: { abc_worksheet: ws, stuck_point: stuck_point })
    end

    nil
  end

  def find_alternative_thought_content(stuck_point, current_path)
    stuck_point.alternative_thoughts.each do |at|
      next unless current_path == alternative_thought_path(at)

      return render_to_string(partial: 'alternative_thoughts/show_content',
                              locals: { alternative_thought: at, stuck_point: stuck_point })
    end

    nil
  end
end
