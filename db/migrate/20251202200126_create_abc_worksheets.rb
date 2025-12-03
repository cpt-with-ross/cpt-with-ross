class CreateAbcWorksheets < ActiveRecord::Migration[7.1]
  def change
    create_table :abc_worksheets do |t|
      t.references :stuck_point, null: false, foreign_key: true
      t.text :activating_event
      t.text :consequence_feeling
      t.integer :feeling_intensity
      t.text :consequence_behaviour

      t.timestamps
    end
  end
end
