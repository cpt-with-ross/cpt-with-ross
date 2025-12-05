module Users
  class SessionsController < Devise::SessionsController
    layout 'auth'

    skip_before_action :set_sidebar_data
  end
end
