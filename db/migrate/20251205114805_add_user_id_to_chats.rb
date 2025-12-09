class AddUserIdToChats < ActiveRecord::Migration[7.1]
  def change
    # Safe: run on empty table during initial setup
    add_reference :chats, :user, null: false, foreign_key: true # rubocop:disable Rails/NotNullColumn
  end
end
