# Idempotent seed data for development/test environments.
# Run with: bin/rails db:seed

user = User.find_or_initialize_by(email: 'example@email.com')
user.password = 'password'
user.save!

index_event = user.index_events.find_or_create_by!(title: 'Car Accident') do |ie|
  ie.date = 6.months.ago
end

index_event.impact_statement.update!(
  statement: 'Since the accident, I have trouble trusting myself to make good decisions. ' \
             'I keep replaying what happened and wonder if I could have done something different.'
)

stuck_point = index_event.stuck_points.find_or_create_by!(statement: 'I should have seen it coming') do |sp|
  sp.belief = 'I am responsible for what happened'
  sp.belief_type = 'self-blame'
  sp.resolved = false
end

stuck_point.abc_worksheets.find_or_create_by!(title: 'Driving anxiety') do |abc|
  abc.activating_event = 'Driving past the intersection where the accident happened'
  abc.beliefs = 'If I had been paying more attention, it would not have happened. I am a bad driver.'
  abc.consequences = 'Anxiety, sweaty palms, avoiding that route entirely'
end

stuck_point.alternative_thoughts.find_or_create_by!(title: 'Reframing responsibility') do |at|
  at.unbalanced_thought = 'I should have seen the other car coming and prevented the accident'
  at.balanced_thought = 'The other driver ran a red light. I could not have predicted or prevented their actions.'
end
