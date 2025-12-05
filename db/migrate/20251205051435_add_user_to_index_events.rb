class AddUserToIndexEvents < ActiveRecord::Migration[7.1]
  def change
    add_reference :index_events, :user, foreign_key: true
  end
end
