# frozen_string_literal: true

# =============================================================================
# ApplicationCable::Channel - Base Channel Class
# =============================================================================
#
# Base class for all ActionCable channels. Provides access to connection
# identifiers (like current_user) and shared channel behavior.
#
# Currently minimal, but can be extended with:
# - Authorization helpers
# - Logging and monitoring
# - Rate limiting
#
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
