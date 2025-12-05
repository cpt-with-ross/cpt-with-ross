class CreateStuckPoints < ActiveRecord::Migration[7.1]
  def change
    create_table :stuck_points do |t|
      t.text :statement
      t.references :index_event, null: false, foreign_key: true

      t.timestamps
    end
  end
end
