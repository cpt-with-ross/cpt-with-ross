# frozen_string_literal: true

# =============================================================================
# AlternativeThought - Challenging Questions Worksheet Record
# =============================================================================
#
# The Alternative Thoughts Worksheet guides users through cognitive restructuring
# by examining stuck points through exploring questions and thinking patterns,
# then developing more balanced alternative thoughts.
#
# Sections:
# - B. Stuck Point: Initial belief rating (0-100%)
# - C. Emotions Before: Initial emotional state
# - D. Exploring Thoughts: 7 questions to examine the stuck point
# - E. Thinking Patterns: 5 cognitive distortion patterns
# - F. Alternative Thought: New balanced thought with belief rating
# - G. Re-rate Stuck Point: Updated belief in original thought
# - H. Emotions After: Final emotional state after worksheet
#
class AlternativeThought < ApplicationRecord
  # The 12 discrete psychological emotions (same as AbcWorksheet)
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

  # D. Exploring thoughts questions
  EXPLORING_QUESTIONS = {
    exploring_evidence_against: 'Evidence against?',
    exploring_missing_info: 'What information is not included?',
    exploring_all_or_none: 'All or none? Extreme?',
    exploring_focused_one_piece: 'Focused on just one piece of the event?',
    exploring_questionable_source: 'Questionable source of information?',
    exploring_confusing_probability: 'Confusing possible with unlikely?',
    exploring_feelings_or_facts: 'Based on feelings or facts?'
  }.freeze

  # E. Thinking patterns
  THINKING_PATTERNS = {
    pattern_jumping_to_conclusions: 'Jumping to conclusions',
    pattern_ignoring_important_parts: 'Ignoring important parts',
    pattern_oversimplifying: 'Oversimplifying/overgeneralizing',
    pattern_mind_reading: 'Mind reading',
    pattern_emotional_reasoning: 'Emotional reasoning'
  }.freeze

  belongs_to :stuck_point, inverse_of: :alternative_thoughts

  validates :stuck_point, presence: true
  validates :stuck_point_belief_before, numericality: { in: 0..100 }, allow_nil: true
  validates :stuck_point_belief_after, numericality: { in: 0..100 }, allow_nil: true
  validates :alternative_thought_belief, numericality: { in: 0..100 }, allow_nil: true
  validate :emotions_before_intensities_within_range
  validate :emotions_after_intensities_within_range

  private

  def emotions_before_intensities_within_range
    validate_emotions_array(:emotions_before)
  end

  def emotions_after_intensities_within_range
    validate_emotions_array(:emotions_after)
  end

  def validate_emotions_array(attribute)
    array = send(attribute)
    return unless array.is_a?(Array)

    array.each do |entry|
      intensity = entry['intensity'].to_i
      next if intensity.between?(0, 10)

      errors.add(attribute, "intensity must be between 0 and 10 (got #{intensity})")
    end
  end

  public

  # Provides a display title, falling back to "Alt Thought #N" if not set.
  # For new records, returns the raw attribute to allow empty display.
  def title
    return self[:title] if new_record?

    self[:title].presence || "Alt Thought ##{id}"
  end

  # Returns the intensity (0-100) for a given emotion in emotions_before
  def emotion_before_intensity(emotion)
    return nil unless emotions_before.is_a?(Array)

    entry = emotions_before.find { |e| e['emotion'] == emotion.to_s }
    entry&.dig('intensity')
  end

  # Returns the intensity (0-100) for a given emotion in emotions_after
  def emotion_after_intensity(emotion)
    return nil unless emotions_after.is_a?(Array)

    entry = emotions_after.find { |e| e['emotion'] == emotion.to_s }
    entry&.dig('intensity')
  end

  # Check if any exploring questions have been answered
  def exploring_complete?
    EXPLORING_QUESTIONS.keys.any? { |field| send(field).present? }
  end

  # Check if any thinking patterns have been answered
  def patterns_complete?
    THINKING_PATTERNS.keys.any? { |field| send(field).present? }
  end
end
