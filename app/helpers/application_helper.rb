module ApplicationHelper
  # Returns all ABC worksheets and Alternative Thoughts for the current user
  # grouped by type with display labels for dropdowns
  def all_user_worksheets
    return [] unless @index_events

    worksheets = []

    @index_events.each do |index_event|
      index_event.stuck_points.each do |stuck_point|
        # Add ABC Worksheets
        stuck_point.abc_worksheets.each do |worksheet|
          worksheets << {
            id: worksheet.id,
            type: 'abc_worksheet',
            label: "ABC: #{worksheet.title} (#{index_event.title})",
            path: abc_worksheet_path(worksheet)
          }
        end

        # Add Alternative Thoughts
        stuck_point.alternative_thoughts.each do |thought|
          worksheets << {
            id: thought.id,
            type: 'alternative_thought',
            label: "Alt: #{thought.title} (#{index_event.title})",
            path: alternative_thought_path(thought)
          }
        end
      end
    end

    worksheets.sort_by { |w| w[:label] }
  end
end
