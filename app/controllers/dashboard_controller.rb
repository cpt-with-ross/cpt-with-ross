# frozen_string_literal: true

# =============================================================================
# DashboardController - Application Entry Point
# =============================================================================
#
# Renders the main application shell at the root path ("/").
# The dashboard view is the container layout with:
# - Left sidebar: Navigation through IndexEvents and their children
# - Center panel: Dynamic content loaded via Turbo Frames
# - Right panel: AI chat interface
#
# The index action is intentionally empty - all data setup happens in
# ApplicationController's before_actions (sidebar data, chat).
#
class DashboardController < ApplicationController
  def index
  end
end
