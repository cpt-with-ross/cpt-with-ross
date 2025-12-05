class CreateAbcWorksheets < ActiveRecord::Migration[7.1]
  def change
    create_table :abc_worksheets do |t|
      t.text :activating_event
      t.text :beliefs
      t.text :consequences
      t.references :stuck_point, null: false, foreign_key: true

      t.timestamps
    end
  end
end
