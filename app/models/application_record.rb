# frozen_string_literal: true

# =============================================================================
# ApplicationRecord - Base Model Class
# =============================================================================
#
# All models inherit from this class. It's configured as Rails' abstract
# base class for the application, allowing for app-wide model configuration.
#
# Currently minimal, but could be extended with:
# - Global scopes
# - Shared validations
# - Audit logging
# - Multi-tenancy support
#
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
