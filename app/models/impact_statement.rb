# frozen_string_literal: true

# =============================================================================
# ImpactStatement - Personal Trauma Impact Narrative
# =============================================================================
#
# An Impact Statement is an early CPT exercise where users write about how
# the traumatic event has affected their lives and beliefs. It covers impact
# on five key areas:
#
# 1. Safety - Beliefs about personal safety and danger
# 2. Trust - Ability to trust self and others
# 3. Power/Control - Sense of agency and control
# 4. Esteem - Self-worth and view of others
# 5. Intimacy - Ability to be close to others
#
# The statement helps users articulate their experience and often reveals
# stuck points that become the focus of later therapy work.
#
# Note: ImpactStatements are 1:1 with IndexEvents and auto-created via callback.
#
class ImpactStatement < ApplicationRecord
  belongs_to :index_event, inverse_of: :impact_statement
end
