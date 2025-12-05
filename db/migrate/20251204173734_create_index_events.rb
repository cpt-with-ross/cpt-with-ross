class CreateIndexEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :index_events do |t|
      t.string :title
      t.date :date

      t.timestamps
    end
  end
end
