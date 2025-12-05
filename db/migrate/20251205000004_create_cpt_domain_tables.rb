# frozen_string_literal: true

class CreateCptDomainTables < ActiveRecord::Migration[7.1]
  def change
    # Index Events - traumatic events being processed
    create_table :index_events do |t|
      t.string :title
      t.date :date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Impact Statements - 1:1 with index events
    create_table :impact_statements do |t|
      t.text :statement
      t.references :index_event, null: false, foreign_key: true

      t.timestamps
    end

    # Stuck Points - negative thoughts/beliefs
    create_table :stuck_points do |t|
      t.text :statement
      t.text :belief
      t.string :belief_type
      t.boolean :resolved
      t.references :index_event, null: false, foreign_key: true

      t.timestamps
    end

    # ABC Worksheets - A-B-C cognitive worksheets
    create_table :abc_worksheets do |t|
      t.string :title
      t.text :activating_event
      t.text :beliefs
      t.text :consequences
      t.references :stuck_point, null: false, foreign_key: true

      t.timestamps
    end

    # Alternative Thoughts - balanced thought challenges
    create_table :alternative_thoughts do |t|
      t.string :title
      t.text :unbalanced_thought
      t.text :balanced_thought
      t.references :stuck_point, null: false, foreign_key: true

      t.timestamps
    end
  end
end
