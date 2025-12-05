# frozen_string_literal: true

# =============================================================================
# ApplicationCable::Connection - WebSocket Authentication
# =============================================================================
#
# Authenticates WebSocket connections using Devise/Warden. Every ActionCable
# connection must be authenticated before channels can be subscribed.
#
# Authentication:
# - Uses Warden (Devise's underlying auth library) to get current user
# - Rejects unauthenticated connections immediately
# - Sets current_user as the connection identifier for authorization checks
#
# This runs once when the WebSocket connection is established, not on each
# channel subscription. The current_user is then available in all channels.
#
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Makes current_user available in all channels for authorization
    identified_by :current_user

    # Called when WebSocket connection is opened
    def connect
      self.current_user = find_verified_user
    end

    private

    # Retrieves authenticated user from Warden (Devise's session store).
    # Warden stores the user in the Rack env from the cookie session.
    def find_verified_user
      if (verified_user = env['warden'].user)
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
