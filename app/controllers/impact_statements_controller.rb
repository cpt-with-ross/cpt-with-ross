# frozen_string_literal: true

# =============================================================================
# ImpactStatementsController - Managing Personal Impact Narratives
# =============================================================================
#
# An Impact Statement is a core CPT exercise where users write about how the
# traumatic event has affected their lives. It's written early in therapy and
# helps identify stuck points and areas for cognitive work.
#
# The statement covers how the event impacted:
# - Safety beliefs
# - Trust in self and others
# - Power and control
# - Esteem (self and others)
# - Intimacy
#
# Unlike other resources, Impact Statements are 1:1 with Index Events (auto-
# created via callback) and cannot be deleted independently.
#
class ImpactStatementsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event
  before_action :set_impact_statement
  before_action :set_statement_focus, only: %i[show edit]

  # Renders the impact statement view in main_content
  def show
  end

  # Renders the edit form for the statement text
  def edit
  end

  # Updates the statement content
  def update
    if @impact_statement.update(impact_statement_params)
      redirect_to index_event_impact_statement_path(@index_event)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Finds parent IndexEvent scoped to current user
  def set_index_event
    @index_event = current_user.index_events.find(params[:index_event_id])
  end

  # Retrieves the impact statement (1:1 relationship with IndexEvent)
  def set_impact_statement
    @impact_statement = @index_event.impact_statement
  end

  def impact_statement_params
    params.require(:impact_statement).permit(:statement)
  end

  # Sets focus context for AI chat when viewing this impact statement
  def set_statement_focus
    set_focus_context(:impact_statement, @impact_statement.id)
  end
end
