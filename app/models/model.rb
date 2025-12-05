# frozen_string_literal: true

# =============================================================================
# Model - LLM Model Configuration Record
# =============================================================================
#
# Stores configuration for LLM models used in chats. Uses RubyLLM's
# acts_as_model pattern for integration with the gem's chat system.
#
# Fields:
# - model_id: The provider's model identifier (e.g., 'gemini-2.0-flash')
# - provider: The LLM provider (e.g., 'google', 'anthropic', 'openai')
# - name: Human-readable display name
#
# Currently the app uses a single default model, but this structure
# allows for future multi-model support (e.g., different models for
# different use cases or user preferences).
#
class Model < ApplicationRecord
  acts_as_model chats_foreign_key: :model_id
end
