# Idempotent seed data for development/test environments.
# Run with: bin/rails db:seed

user = User.find_or_initialize_by(email: 'example@email.com')
user.password = 'password'
user.save!

index_event = user.index_events.find_or_create_by!(title: 'Car Accident') do |ie|
  ie.date = 6.months.ago
end

index_event.baseline.update!(
  statement: 'Since the accident, I have trouble trusting myself to make good decisions. ' \
             'I keep replaying what happened and wonder if I could have done something different.',
  event_description: 'I was driving through an intersection when another car ran a red light and ' \
                     'hit the passenger side of my vehicle. My car spun and hit a light pole.',
  time_since_event: '6 months',
  involved_death_injury_violence: true,
  experience_type: 'direct',
  death_cause_type: 'not_applicable',
  pcl_disturbing_memories: 3,
  pcl_disturbing_dreams: 2,
  pcl_flashbacks: 2,
  pcl_upset_reminders: 4,
  pcl_physical_reactions: 3,
  pcl_avoiding_memories: 2,
  pcl_avoiding_reminders: 3,
  pcl_trouble_remembering: 1,
  pcl_negative_beliefs: 3,
  pcl_blaming: 4,
  pcl_negative_feelings: 3,
  pcl_loss_of_interest: 2,
  pcl_feeling_distant: 2,
  pcl_trouble_positive_feelings: 2,
  pcl_irritable_behavior: 2,
  pcl_risky_behavior: 0,
  pcl_super_alert: 3,
  pcl_jumpy: 3,
  pcl_difficulty_concentrating: 2,
  pcl_sleep_trouble: 3
)

stuck_point = index_event.stuck_points.find_or_create_by!(statement: 'I should have seen it coming')

stuck_point.abc_worksheets.find_or_create_by!(title: 'Driving anxiety') do |abc|
  abc.activating_event = 'Driving past the intersection where the accident happened'
  abc.beliefs = 'If I had been paying more attention, it would not have happened. I am a bad driver.'
  abc.consequences = 'Anxiety, sweaty palms, avoiding that route entirely'
  abc.emotions = [
    { 'emotion' => 'fear', 'intensity' => 8 },
    { 'emotion' => 'guilt', 'intensity' => 7 },
    { 'emotion' => 'shame', 'intensity' => 5 }
  ]
end

stuck_point.alternative_thoughts.find_or_create_by!(title: 'Reframing responsibility') do |at|
  at.alternative_thought = 'The other driver ran a red light. I could not have predicted or prevented their actions.'
  at.stuck_point_belief_before = 85
  at.stuck_point_belief_after = 40

  # Section C: Initial emotions (0-10 scale)
  at.emotions_before = [
    { 'emotion' => 'guilt', 'intensity' => 8 },
    { 'emotion' => 'shame', 'intensity' => 7 },
    { 'emotion' => 'fear', 'intensity' => 6 }
  ]

  # Section D: Exploring thoughts
  at.exploring_evidence_against = 'The police report states the other driver ran a red light. ' \
                                  'Witnesses confirmed I had a green light.'
  at.exploring_feelings_or_facts = 'My feeling that I should have seen it coming is based on ' \
                                   'hindsight, not facts available at the time.'
  at.exploring_missing_info = 'I am ignoring that the other car was speeding and came from a ' \
                              'blind spot created by a parked truck.'
  at.exploring_all_or_none = 'I am thinking in all-or-none terms: either I prevented the ' \
                             'accident entirely or I am completely at fault.'
  at.exploring_questionable_source = 'My self-blame comes from my own anxious thoughts, not ' \
                                     'from any external evidence or feedback.'
  at.exploring_focused_one_piece = 'I am focused only on what I could have done differently, ' \
                                   'ignoring the other driver\'s illegal actions.'
  at.exploring_confusing_probability = 'I am treating a rare, unpredictable event as something ' \
                                       'that was likely and should have been anticipated.'

  # Section E: Thinking patterns
  at.pattern_jumping_to_conclusions = 'I jumped to the conclusion that I must be at fault ' \
                                      'without considering all the evidence.'
  at.pattern_ignoring_important_parts = 'I ignored that the other driver was cited by police ' \
                                        'and that I was legally in the right.'
  at.pattern_oversimplifying = 'I oversimplified a complex situation into "I should have ' \
                               'prevented it" when many factors were involved.'
  at.pattern_mind_reading = 'I assumed others would blame me for the accident, when in ' \
                            'reality no one has expressed that.'
  at.pattern_emotional_reasoning = 'Because I feel guilty, I assumed I must be guilty, ' \
                                   'even though feelings are not facts.'

  # Section F: Alternative thought belief rating
  at.alternative_thought_belief = 75

  # Section H: Final emotions (0-10 scale)
  at.emotions_after = [
    { 'emotion' => 'guilt', 'intensity' => 4 },
    { 'emotion' => 'shame', 'intensity' => 3 },
    { 'emotion' => 'fear', 'intensity' => 4 },
    { 'emotion' => 'sadness', 'intensity' => 5 }
  ]
end
