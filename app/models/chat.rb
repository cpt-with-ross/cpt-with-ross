# frozen_string_literal: true

# =============================================================================
# Chat - AI Conversation Session
# =============================================================================
#
# Represents a conversation session with the AI therapist "Ross". Uses the
# RubyLLM gem's acts_as_chat pattern for LLM integration.
#
# Design:
# - Each user has one persistent chat (created on first visit)
# - Messages are stored and can be cleared without deleting the chat
# - The associated Model record determines which LLM to use
#
# RubyLLM Integration:
# acts_as_chat provides: #ask, #messages, #with_model, streaming support.
# However, we bypass some of these in CptChatService for better control
# over RAG context injection and message persistence.
#
class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id

  belongs_to :user, inverse_of: :chats
  belongs_to :model, optional: true

  # Returns the model identifier string (e.g., 'gemini-2.0-flash')
  # Falls back to config defaults if no model is associated
  def llm_model_id
    model&.model_id || Rails.application.config.cpt_chat[:default_model_id]
  end

  # Returns the provider string (e.g., 'google')
  # Falls back to config defaults if no model is associated
  def llm_provider
    model&.provider || Rails.application.config.cpt_chat[:default_provider]
  end

  # Finds or creates the default Model record for new chats.
  # Uses find_or_create_by to ensure idempotency.
  def self.find_or_create_default_model
    config = Rails.application.config.cpt_chat
    Model.find_or_create_by!(
      model_id: config[:default_model_id],
      provider: config[:default_provider]
    ) { |m| m.name = config[:default_model_id] }
  end
end
