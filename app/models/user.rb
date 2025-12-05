# frozen_string_literal: true

# =============================================================================
# User - Application User Account
# =============================================================================
#
# Represents an authenticated user of the CPT application. Users own all their
# therapy data (index events, stuck points, worksheets) and have an AI chat.
#
# Authentication is handled by Devise with email/password.
#
# Associations:
# - index_events: The traumatic events being processed
# - chats: AI chat sessions (typically one persistent chat per user)
# - stuck_points: Accessible via through association for convenience
#
class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :index_events, dependent: :destroy, inverse_of: :user
  has_many :chats, dependent: :destroy, inverse_of: :user
  has_many :stuck_points, through: :index_events
end
