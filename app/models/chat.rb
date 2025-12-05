# RubyLLM gem integration for AI chat functionality.
# acts_as_chat provides: #ask, #messages, #with_model, and streaming support.
class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id

  belongs_to :user, inverse_of: :chats
  belongs_to :model, optional: true

  # Returns the model identifier string (e.g., 'gemini-2.5-flash')
  def llm_model_id
    model&.model_id || Rails.application.config.cpt_chat[:default_model_id]
  end

  # Returns the provider string (e.g., 'vertexai')
  def llm_provider
    model&.provider || Rails.application.config.cpt_chat[:default_provider]
  end

  # Finds or creates the default Model record for new chats
  def self.find_or_create_default_model
    config = Rails.application.config.cpt_chat
    Model.find_or_create_by!(
      model_id: config[:default_model_id],
      provider: config[:default_provider]
    ) { |m| m.name = config[:default_model_id] }
  end
end
