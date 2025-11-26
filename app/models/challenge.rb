class Challenge < ApplicationRecord
  belongs_to :user
  has_one :chat

  after_create :create_associated_chat

  private
  
  def create_associated_chat
    create_chat
  end

end
