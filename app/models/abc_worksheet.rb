class AbcWorksheet < ApplicationRecord
  belongs_to :stuck_point, inverse_of: :abc_worksheets

  def title
    return self[:title] if new_record?

    self[:title].presence || "ABC ##{id}"
  end
end
