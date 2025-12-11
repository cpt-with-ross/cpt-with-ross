# frozen_string_literal: true

# Demo seed data for CPT with Ross - Run with: bin/rails db:seed

puts 'Creating demo data...'

user = User.find_or_initialize_by(email: 'test@cptwithross.com')
user.password = 'test123'
user.save!

# =============================================================================
# Motor Vehicle Accident - Complete therapy journey
# =============================================================================

event = user.index_events.find_or_create_by!(title: 'Motor Vehicle Accident') do |ie|
  ie.date = 6.months.ago
end

event.baseline.update!(
  statement: 'Since the accident, I have lost trust in my own judgment. I question every ' \
             'decision I make. The world feels dangerous and I avoid driving whenever possible.',
  event_description: 'I was driving home when a distracted driver ran a red light and T-boned ' \
                     'my car. I was trapped for 45 minutes. I could see the other driver on their phone.',
  time_since_event: '6 months',
  involved_death_injury_violence: true,
  experience_type: 'direct',
  death_cause_type: 'not_applicable',
  pcl_disturbing_memories: 3, pcl_disturbing_dreams: 3, pcl_flashbacks: 2,
  pcl_upset_reminders: 4, pcl_physical_reactions: 4, pcl_avoiding_memories: 3,
  pcl_avoiding_reminders: 4, pcl_trouble_remembering: 1, pcl_negative_beliefs: 3,
  pcl_blaming: 3, pcl_negative_feelings: 3, pcl_loss_of_interest: 2,
  pcl_feeling_distant: 3, pcl_trouble_positive_feelings: 2, pcl_irritable_behavior: 3,
  pcl_risky_behavior: 0, pcl_super_alert: 4, pcl_jumpy: 4,
  pcl_difficulty_concentrating: 3, pcl_sleep_trouble: 3
)

# Stuck Point with ABC Worksheet and Alternative Thought
sp = event.stuck_points.find_or_create_by!(
  statement: 'I should have been more vigilant and seen the other car coming'
)

sp.abc_worksheets.find_or_create_by!(title: 'Driving past the intersection') do |abc|
  abc.activating_event = 'Driving past the intersection where the accident happened.'
  abc.beliefs = sp.statement
  abc.consequences = 'Heart racing, gripped wheel tight, almost pulled over. Sat in parking lot crying.'
  abc.emotions = [
    { 'emotion' => 'fear', 'intensity' => 9 },
    { 'emotion' => 'guilt', 'intensity' => 7 },
    { 'emotion' => 'shame', 'intensity' => 6 }
  ]
end

sp.alternative_thoughts.find_or_create_by!(title: 'Reframing responsibility') do |at|
  at.stuck_point_belief_before = 85
  at.emotions_before = [
    { 'emotion' => 'guilt', 'intensity' => 8 },
    { 'emotion' => 'shame', 'intensity' => 7 },
    { 'emotion' => 'fear', 'intensity' => 6 }
  ]
  at.exploring_evidence_against = 'The police report confirms the other driver ran a red light. ' \
                                  'Witnesses stated I had a green light. Insurance found me 0% at fault.'
  at.exploring_feelings_or_facts = 'My feeling is based on hindsight, not facts available at the time.'
  at.exploring_all_or_none = 'I am thinking all-or-none: either I prevented it or I am completely at fault.'
  at.pattern_jumping_to_conclusions = 'I concluded I was at fault without gathering all facts.'
  at.pattern_emotional_reasoning = 'Because I feel guilty, I assumed I must be guilty.'
  at.alternative_thought = 'The accident was caused by the other driver who ran a red light. ' \
                           'I was driving safely. No vigilance prevents every accident. I did nothing wrong.'
  at.alternative_thought_belief = 75
  at.stuck_point_belief_after = 35
  at.emotions_after = [
    { 'emotion' => 'guilt', 'intensity' => 3 },
    { 'emotion' => 'sadness', 'intensity' => 5 },
    { 'emotion' => 'anger', 'intensity' => 4 }
  ]
end

puts ''
puts 'Demo ready!'
puts '  Email: test@cptwithross.com'
puts '  Password: test123'
puts "  PCL-5 Score: #{event.baseline.pcl_total_score}/80"
