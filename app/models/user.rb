class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :index_events, dependent: :destroy, inverse_of: :user
end
