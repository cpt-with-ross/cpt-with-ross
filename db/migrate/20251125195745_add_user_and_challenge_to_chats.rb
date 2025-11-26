class AddUserAndChallengeToChats < ActiveRecord::Migration[7.1]
  def change
    add_reference :chats, :user, null: false, foreign_key: true
    add_reference :chats, :challenge, null: false, foreign_key: true
    add_index :chats, %i[user_id challenge_id], unique: true
  end
end
