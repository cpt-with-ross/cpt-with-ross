class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :index_events, dependent: :destroy, inverse_of: :user
  has_many :chats, dependent: :destroy, inverse_of: :user
  has_many :stuck_points, through: :index_events
end
