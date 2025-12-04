# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Create one user -> one index_event -> one stuck_point -> one impact_statement -> one alternative_thought

ActiveRecord::Base.transaction do
	user = User.find_or_create_by!(email: 'seed@example.com') do |u|
		u.password = 'password123'
		u.password_confirmation = 'password123'
	end

	index_event = IndexEvent.find_or_create_by!(name: 'Car accident', user: user) do |t|
		t.event_date = Date.new(2020, 1, 1)
	end

	stuck_point = StuckPoint.find_or_create_by!(title: 'I am to blame', index_event: index_event) do |s|
		s.belief = 'I caused the accident'
		s.belief_type = 'global'
		s.resolved = false
	end

	impact = ImpactStatement.find_or_create_by!(index_event: index_event) do |i|
		i.content = 'The accident affected my relationships and confidence.'
	end

	alt = AlternativeThought.find_or_create_by!(stuck_point: stuck_point, alternative_thought: 'It was an accident') do |a|
		a.evidence_for = 'Weather and road conditions were poor and an independent report found no reckless driving.'
		a.evidence_against = 'I was driving at the time of the incident.'
		a.belief_rating = 60
	end
end
