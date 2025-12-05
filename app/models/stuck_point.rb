class StuckPoint < ApplicationRecord
  belongs_to :index_event, inverse_of: :stuck_points
  has_many :abc_worksheets, dependent: :destroy, inverse_of: :stuck_point
  has_many :alternative_thoughts, dependent: :destroy, inverse_of: :stuck_point

  validates :statement, presence: true

  def title
    statement
  end
end
