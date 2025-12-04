class StuckPoint < ApplicationRecord
  belongs_to :trauma
  has_many :abc_worksheets, dependent: :destroy
  has_many :alternative_thoughts, dependent: :destroy

  validates :title, presence: true
  validates :belief, presence: true
end
