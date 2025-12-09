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

    # Baselines - 1:1 with index events, includes PTSD checklist
    create_table :baselines do |t|
      t.text :statement
      t.references :index_event, null: false, foreign_key: true

      # Event identification
      t.text :event_description
      t.string :time_since_event
      t.boolean :involved_death_injury_violence # rubocop:disable Rails/ThreeStateBooleanColumn -- nullable represents unanswered
      t.string :experience_type
      t.text :experience_other_description
      t.string :death_cause_type

      # PCL-5 Symptom Checklist (0-4 scale for each)
      t.integer :pcl_disturbing_memories
      t.integer :pcl_disturbing_dreams
      t.integer :pcl_flashbacks
      t.integer :pcl_upset_reminders
      t.integer :pcl_physical_reactions
      t.integer :pcl_avoiding_memories
      t.integer :pcl_avoiding_reminders
      t.integer :pcl_trouble_remembering
      t.integer :pcl_negative_beliefs
      t.integer :pcl_blaming
      t.integer :pcl_negative_feelings
      t.integer :pcl_loss_of_interest
      t.integer :pcl_feeling_distant
      t.integer :pcl_trouble_positive_feelings
      t.integer :pcl_irritable_behavior
      t.integer :pcl_risky_behavior
      t.integer :pcl_super_alert
      t.integer :pcl_jumpy
      t.integer :pcl_difficulty_concentrating
      t.integer :pcl_sleep_trouble

      t.timestamps
    end

    # Stuck Points - negative thoughts/beliefs
    create_table :stuck_points do |t|
      t.text :statement
      t.boolean :resolved, default: false, null: false
      t.references :index_event, null: false, foreign_key: true

      t.timestamps
    end

    # ABC Worksheets - A-B-C cognitive worksheets
    create_table :abc_worksheets do |t|
      t.string :title
      t.text :activating_event
      t.text :beliefs
      t.text :consequences
      t.jsonb :emotions, default: []
      t.references :stuck_point, null: false, foreign_key: true

      t.timestamps
    end

    # Alternative Thoughts - balanced thought challenges (full worksheet)
    create_table :alternative_thoughts do |t|
      t.string :title
      t.text :alternative_thought
      t.references :stuck_point, null: false, foreign_key: true

      # Section B: Initial stuck point belief rating (0-100%)
      t.integer :stuck_point_belief_before

      # Section C: Initial emotions
      t.jsonb :emotions_before, default: []

      # Section D: Exploring thoughts questions
      t.text :exploring_evidence_against
      t.text :exploring_feelings_or_facts
      t.text :exploring_missing_info
      t.text :exploring_all_or_none
      t.text :exploring_questionable_source
      t.text :exploring_focused_one_piece
      t.text :exploring_confusing_probability

      # Section E: Thinking patterns
      t.text :pattern_jumping_to_conclusions
      t.text :pattern_ignoring_important_parts
      t.text :pattern_oversimplifying
      t.text :pattern_mind_reading
      t.text :pattern_emotional_reasoning

      # Section F: Alternative thought belief rating (0-100%)
      t.integer :alternative_thought_belief

      # Section G: Re-rated stuck point belief (0-100%)
      t.integer :stuck_point_belief_after

      # Section H: Final emotions
      t.jsonb :emotions_after, default: []

      t.timestamps
    end
  end
end
