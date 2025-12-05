class StuckPoint < ApplicationRecord
  belongs_to :index_event
  has_many :abc_worksheets, dependent: :destroy
  has_many :alternative_thoughts, dependent: :destroy

  validates :statement, presence: true

  def title
    statement
  end
end
