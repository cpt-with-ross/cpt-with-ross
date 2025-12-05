class AlternativeThought < ApplicationRecord
  belongs_to :stuck_point, inverse_of: :alternative_thoughts

  def title
    return self[:title] if new_record?

    self[:title].presence || "Alt Thought ##{id}"
  end
end
