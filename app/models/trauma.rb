class Trauma < ApplicationRecord
  belongs_to :user
  has_many :impact_statements
  has_many :stuck_points
end
