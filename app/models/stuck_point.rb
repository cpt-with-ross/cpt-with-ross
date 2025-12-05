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
  belongs_to :index_event, inverse_of: :stuck_points
  has_many :abc_worksheets, dependent: :destroy, inverse_of: :stuck_point
  has_many :alternative_thoughts, dependent: :destroy, inverse_of: :stuck_point

  validates :statement, presence: true

  # Alias for consistent interface with other sidebar resources
  def title
    statement
  end
end
