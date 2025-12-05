# Background job for updating ABC worksheet beliefs when a stuck point changes.
# Ensures worksheet beliefs stay in sync with their parent stuck point statement.
class UpdateAbcBeliefsJob < ApplicationJob
  queue_as :default

  def perform(stuck_point_id, new_statement)
    stuck_point = StuckPoint.find_by(id: stuck_point_id)
    return unless stuck_point

    # rubocop:disable Rails/SkipsModelValidations
    updated_count = stuck_point.abc_worksheets.update_all(beliefs: new_statement)
    # rubocop:enable Rails/SkipsModelValidations

    Rails.logger.info("UpdateAbcBeliefsJob: Updated #{updated_count} ABC worksheets for StuckPoint##{stuck_point_id}")
  end
end
