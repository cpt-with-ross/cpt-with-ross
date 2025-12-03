class StuckPoint < ApplicationRecord
  belongs_to :trauma
  has_many :abc_worksheets
  has_many :alternative_thoughts

  validates :title, presence: true
  validates :belief, presence: true
end
