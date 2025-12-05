# frozen_string_literal: true

# =============================================================================
# ToolCall - LLM Function Call Record
# =============================================================================
#
# Stores records of function/tool calls made by the LLM during conversations.
# Uses RubyLLM's acts_as_tool_call pattern.
#
# Tool calls are how LLMs can interact with external systems - the model
# requests to call a function with specific arguments, and the application
# executes it and returns results.
#
# Currently not actively used in this app (Ross doesn't have tools), but
# the infrastructure is in place for future expansion (e.g., scheduling
# appointments, looking up resources, etc.).
#
class ToolCall < ApplicationRecord
  acts_as_tool_call
end
