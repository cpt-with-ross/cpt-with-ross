class ImpactStatement < ApplicationRecord
  belongs_to :index_event, inverse_of: :impact_statement
end
