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
# - consequences: Legacy text field for emotions/behaviors
# - emotions: JSONB array of {emotion:, intensity:} for structured emotion tracking
#
class AbcWorksheet < ApplicationRecord
  # The 12 discrete psychological emotions (non-reducible lexicon)
  EMOTIONS = %w[
    anger
    anticipation
    awe
    contempt
    disgust
    fear
    guilt
    joy
    sadness
    shame
    surprise
    trust
  ].freeze

  belongs_to :stuck_point, inverse_of: :abc_worksheets

  validate :emotions_intensities_within_range

  private

  def emotions_intensities_within_range
    return unless emotions.is_a?(Array)

    emotions.each do |entry|
      intensity = entry['intensity'].to_i
      next if intensity.between?(0, 10)

      errors.add(:emotions, "intensity must be between 0 and 10 (got #{intensity})")
    end
  end

  public

  # Provides a display title, falling back to "ABC #N" if not set.
  # For new records, returns the raw attribute to allow empty display.
  def title
    return self[:title] if new_record?

    self[:title].presence || "ABC ##{id}"
  end

  # Provides beliefs with fallback to "Stuck Point #N" if not set.
  # Uses stuck_point.id for consistency with StuckPoint#statement fallback.
  # For new records, returns the raw attribute to allow empty display.
  def beliefs
    return self[:beliefs] if new_record?

    self[:beliefs].presence || "Stuck Point ##{stuck_point_id}"
  end

  # Returns the intensity (0-10) for a given emotion, or nil if not set
  def emotion_intensity(emotion)
    return nil unless emotions.is_a?(Array)

    entry = emotions.find { |e| e['emotion'] == emotion.to_s }
    entry&.dig('intensity')
  end
end
