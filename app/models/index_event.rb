class IndexEvent < ApplicationRecord
  has_one :impact_statement, dependent: :destroy
  has_many :stuck_points, dependent: :destroy

  validates :title, presence: true

  # CPT workflow requires every IndexEvent to have an ImpactStatement for the patient
  # to document how the traumatic event has affected their beliefs and daily life.
  after_create :create_impact_statement
end
