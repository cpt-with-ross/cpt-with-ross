# frozen_string_literal: true

# =============================================================================
# Users::SessionsController - Authentication Session Management
# =============================================================================
#
# Customizes Devise's SessionsController for login/logout functionality.
#
# Customizations:
# - Uses 'auth' layout instead of 'application' for login pages
# - Skips sidebar data loading (not needed on login page)
#
module Users
  class SessionsController < Devise::SessionsController
    layout 'auth'

    # Login page doesn't need the sidebar data that ApplicationController loads
    skip_before_action :set_sidebar_data
  end
end
