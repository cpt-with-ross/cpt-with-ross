class Trauma < ApplicationRecord
  belongs_to :user
  has_many :stuck_points
  attr_reader :trauma_name

end
