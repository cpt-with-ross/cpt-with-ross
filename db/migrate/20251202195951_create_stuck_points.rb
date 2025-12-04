class CreateStuckPoints < ActiveRecord::Migration[7.1]
  def change
    create_table :stuck_points do |t|
      t.string :title
      t.references :index_event, null: false, foreign_key: true
      t.text :belief
      t.string :belief_type
      t.boolean :resolved

      t.timestamps
    end
  end
end
