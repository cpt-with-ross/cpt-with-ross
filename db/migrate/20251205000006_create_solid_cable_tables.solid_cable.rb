# frozen_string_literal: true

# This migration comes from solid_cable
class CreateSolidCableTables < ActiveRecord::Migration[7.1]
  def change
    create_table :solid_cable_messages do |t|
      t.text :channel
      t.text :payload

      t.timestamps

      t.index :channel
      t.index :created_at
    end
  end
end
