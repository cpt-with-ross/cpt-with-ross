class CreateImpactStatements < ActiveRecord::Migration[7.1]
  def change
    create_table :impact_statements do |t|
      t.text :content
      t.references :index_event, null: false, foreign_key: true

      t.timestamps
    end
  end
end
