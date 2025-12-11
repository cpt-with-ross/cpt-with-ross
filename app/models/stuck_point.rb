# frozen_string_literal: true

# =============================================================================
# StuckPoint - Cognitive Stuck Point / Unhelpful Belief
# =============================================================================
#
# A "stuck point" is a CPT term for thoughts or beliefs that keep someone
# "stuck" after trauma. They're typically:
# - Over-generalizations ("No one can be trusted")
# - Self-blame ("I should have prevented it")
# - Distorted safety beliefs ("The world is completely dangerous")
#
# Stuck points are the focus of cognitive restructuring work. Users identify
# them, analyze them via ABC worksheets, and develop alternative thoughts
# that are more balanced and helpful.
#
# The `statement` field contains the actual stuck point text. The `title`
# method aliases this for consistent API across resources in the sidebar.
#
class StuckPoint < ApplicationRecord
  RESOURCE_TYPE = 'Stuck Point'

  belongs_to :index_event, inverse_of: :stuck_points
  has_many :abc_worksheets, dependent: :destroy, inverse_of: :stuck_point
  has_many :alternative_thoughts, dependent: :destroy, inverse_of: :stuck_point

  # Provides the statement with fallback to "Stuck Point #N" if not set.
  # For new records, returns the raw attribute to allow empty display.
  # Note: Uses own ID for fallback (consistent with title methods across models)
  def statement
    return self[:statement] if new_record?

    self[:statement].presence || "Stuck Point ##{id}"
  end

  # Syncs the statement to all ABC worksheets' beliefs field.
  # Optionally excludes a specific worksheet (e.g., the one just updated).
  def sync_beliefs_to_worksheets(except_id: nil)
    scope = abc_worksheets
    scope = scope.where.not(id: except_id) if except_id
    scope.find_each { |ws| ws.update(beliefs: statement) }
  end
end
