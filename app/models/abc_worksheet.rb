class AbcWorksheet < ApplicationRecord
  belongs_to :stuck_point

  def title
    return self[:title] if new_record?

    self[:title].presence || "ABC ##{id}"
  end
end
