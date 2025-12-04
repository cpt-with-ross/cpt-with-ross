class IndexEvent < ApplicationRecord
  belongs_to :user
  has_one :impact_statement, dependent: :destroy
  has_many :stuck_points, dependent: :destroy
  # has_many :worksheets, dependent: :destroy
  validates :name, presence: true
  validates :event_date, presence: true
end
