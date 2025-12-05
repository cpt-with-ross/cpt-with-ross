class AddFieldsToStuckPoints < ActiveRecord::Migration[7.1]
  def change
    add_column :stuck_points, :belief, :text
    add_column :stuck_points, :belief_type, :string
    add_column :stuck_points, :resolved, :boolean
  end
end
