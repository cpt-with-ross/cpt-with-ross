# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# --- User ---
user = User.find_or_initialize_by(email: 'example@email.com')
user.password = 'password'
user.save!

# --- Index Events (CPT Therapy Data) ---
index_event = user.index_events.find_or_create_by!(title: 'Sample Traumatic Event') do |ie|
  ie.date = 1.year.ago
end

# The impact_statement is auto-created via after_create callback on IndexEvent

# --- Stuck Points ---
index_event.stuck_points.find_or_create_by!(statement: 'I should have been able to prevent it') do |sp|
  sp.belief = 'I am responsible for what happened'
  sp.belief_type = 'self-blame'
  sp.resolved = false
end
