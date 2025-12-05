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
user = User.new({ 'email' => 'example@email.com', 'reset_password_token' => nil, 'reset_password_sent_at' => nil,
                  'remember_created_at' => nil })
user.password = 'password'
user.save
