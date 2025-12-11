class AddTtsTimepointsToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :tts_timepoints, :jsonb
  end
end
