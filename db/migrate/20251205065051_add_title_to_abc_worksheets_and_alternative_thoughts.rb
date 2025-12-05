class AddTitleToAbcWorksheetsAndAlternativeThoughts < ActiveRecord::Migration[7.1]
  def change
    add_column :abc_worksheets, :title, :string
    add_column :alternative_thoughts, :title, :string
  end
end
