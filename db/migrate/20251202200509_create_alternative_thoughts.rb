class CreateAlternativeThoughts < ActiveRecord::Migration[7.1]
  def change
    create_table :alternative_thoughts do |t|
      t.references :stuck_point, null: false, foreign_key: true
      t.text :evidence_for
      t.text :evidence_against
      t.text :alternative_thought
      t.integer :belief_rating

      t.timestamps
    end
  end
end
