# frozen_string_literal: true

# =============================================================================
# IndexEvent - Traumatic Event Record
# =============================================================================
#
# The "index event" in CPT terminology refers to the primary traumatic event
# the patient is processing in therapy. It's the root of the therapy work -
# all stuck points, worksheets, and alternative thoughts relate back to this.
#
# Users may have multiple index events if they experienced multiple traumas,
# though CPT typically focuses on one primary event at a time.
#
# Hierarchy:
#   IndexEvent
#   ├── Baseline (1:1, auto-created)
#   └── StuckPoints[] (1:many)
#       ├── AbcWorksheets[]
#       └── AlternativeThoughts[]
#
class IndexEvent < ApplicationRecord
  belongs_to :user, inverse_of: :index_events
  has_one :baseline, dependent: :destroy, inverse_of: :index_event
  has_many :stuck_points, dependent: :destroy, inverse_of: :index_event

  # Every IndexEvent requires a Baseline - auto-create on save to
  # ensure the CPT workflow can proceed immediately after event creation.
  after_create :create_baseline

  # Provides a display title, falling back to "Index Event #N" if not set.
  # For new records, returns the raw attribute to allow empty display.
  def title
    return self[:title] if new_record?

    self[:title].presence || "Index Event ##{id}"
  end
end
