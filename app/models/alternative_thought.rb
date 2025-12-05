# frozen_string_literal: true

# =============================================================================
# AlternativeThought - Balanced Thought Challenge Record
# =============================================================================
#
# Alternative Thoughts are the outcome of cognitive restructuring in CPT.
# After identifying and analyzing a stuck point, users develop more balanced
# perspectives that account for all the evidence.
#
# Structure:
# - unbalanced_thought: The original stuck point (e.g., "I can't trust anyone")
# - balanced_thought: A more realistic perspective (e.g., "While some people
#   have hurt me, I can evaluate trustworthiness over time")
#
# The goal isn't "positive thinking" but rather accurate, balanced thinking
# that acknowledges both the trauma and possibilities for healing.
#
class AlternativeThought < ApplicationRecord
  belongs_to :stuck_point, inverse_of: :alternative_thoughts

  # Provides a display title, falling back to "Alt Thought #N" if not set.
  # For new records, returns the raw attribute to allow empty display.
  def title
    return self[:title] if new_record?

    self[:title].presence || "Alt Thought ##{id}"
  end
end
