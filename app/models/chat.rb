# RubyLLM gem integration for AI chat functionality.
# acts_as_chat provides: #ask, #messages, #with_model, and streaming support.
class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id
end
