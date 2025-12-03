class CreateTraumas < ActiveRecord::Migration[7.1]
  def change
    create_table :traumas do |t|
      t.string :name
      t.date :event_date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
