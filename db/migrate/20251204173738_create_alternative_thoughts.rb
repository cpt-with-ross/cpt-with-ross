class CreateAlternativeThoughts < ActiveRecord::Migration[7.1]
  def change
    create_table :alternative_thoughts do |t|
      t.text :unbalanced_thought
      t.text :balanced_thought
      t.references :stuck_point, null: false, foreign_key: true

      t.timestamps
    end
  end
end
