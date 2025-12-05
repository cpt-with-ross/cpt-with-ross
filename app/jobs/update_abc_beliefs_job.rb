# frozen_string_literal: true

# =============================================================================
# UpdateAbcBeliefsJob - ABC Worksheet Synchronization
# =============================================================================
#
# Maintains consistency between stuck points and their associated ABC worksheets.
#
# In CPT therapy, stuck points evolve as patients gain insight. When a stuck
# point's statement is updated, all ABC worksheets that reference it should
# reflect the updated belief text. This job handles that synchronization
# asynchronously to keep the UI responsive.
#
# Why async? A stuck point might have many worksheets, and we don't want to
# block the user's update request while cascading changes.
#
class UpdateAbcBeliefsJob < ApplicationJob
  queue_as :default

  def perform(stuck_point_id, new_statement)
    stuck_point = StuckPoint.find_by(id: stuck_point_id)
    return unless stuck_point # Gracefully handle if deleted before job runs

    # Bulk update for efficiency - bypasses callbacks since we're just
    # synchronizing data, not triggering business logic
    # rubocop:disable Rails/SkipsModelValidations
    updated_count = stuck_point.abc_worksheets.update_all(beliefs: new_statement)
    # rubocop:enable Rails/SkipsModelValidations

    Rails.logger.info("UpdateAbcBeliefsJob: Updated #{updated_count} ABC worksheets for StuckPoint##{stuck_point_id}")
  end
end
