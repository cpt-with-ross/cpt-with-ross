# frozen_string_literal: true

# =============================================================================
# AbcWorksheet - A-B-C Cognitive Analysis Worksheet
# =============================================================================
#
# The ABC Worksheet is a CPT tool for understanding the connection between
# situations, thoughts, and emotional reactions:
#
# - A (Activating Event): The trigger situation or memory
# - B (Beliefs): The stuck point or automatic thought that arose
# - C (Consequences): The emotional and behavioral outcomes
#
# This helps users see that it's not events (A) that directly cause
# distress (C), but rather their beliefs about events (B). This insight
# is foundational for cognitive restructuring.
#
# Fields:
# - activating_event: Text describing the situation
# - beliefs: The stuck point (synced with parent StuckPoint.statement)
# - consequences: Emotions and behaviors that resulted
#
class AbcWorksheet < ApplicationRecord
  belongs_to :stuck_point, inverse_of: :abc_worksheets

  # Provides a display title, falling back to "ABC #N" if not set.
  # For new records, returns the raw attribute to allow empty display.
  def title
    return self[:title] if new_record?

    self[:title].presence || "ABC ##{id}"
  end
end
