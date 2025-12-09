# frozen_string_literal: true

# =============================================================================
# BaselinesController - Managing Personal Baseline Assessments
# =============================================================================
#
# A Baseline is a core CPT exercise where users complete the PTSD checklist
# and write about how the traumatic event has affected their lives. It's
# completed early in therapy and helps identify stuck points and areas for
# cognitive work.
#
# The baseline covers how the event impacted:
# - Safety beliefs
# - Trust in self and others
# - Power and control
# - Esteem (self and others)
# - Intimacy
#
# Unlike other resources, Baselines are 1:1 with Index Events (auto-
# created via callback) and cannot be deleted independently.
#
class BaselinesController < ApplicationController
  include InlineFormRenderable

  VALID_SECTIONS = %w[checklist pcl statement].freeze

  before_action :set_index_event
  before_action :set_baseline
  before_action :set_section, only: %i[edit update]
  before_action :set_baseline_focus, only: %i[show edit]

  # Renders the baseline view in main_content
  def show
  end

  # Renders the edit form for the selected section
  def edit
  end

  # Updates the baseline content and redirects to show page
  def update
    if @baseline.update(baseline_params)
      redirect_to index_event_baseline_path(@index_event), notice: 'Saved successfully.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Finds parent IndexEvent scoped to current user
  def set_index_event
    @index_event = current_user.index_events.find(params[:index_event_id])
  end

  # Retrieves the baseline (1:1 relationship with IndexEvent)
  def set_baseline
    @baseline = @index_event.baseline
  end

  def baseline_params
    params.require(:baseline).permit(
      # Page 1: Baseline PTSD Checklist - Event Identification
      :event_description,
      :time_since_event,
      :involved_death_injury_violence,
      :experience_type,
      :experience_other_description,
      :death_cause_type,
      # Page 2: PCL-5 Symptom Checklist
      :pcl_disturbing_memories,
      :pcl_disturbing_dreams,
      :pcl_flashbacks,
      :pcl_upset_reminders,
      :pcl_physical_reactions,
      :pcl_avoiding_memories,
      :pcl_avoiding_reminders,
      :pcl_trouble_remembering,
      :pcl_negative_beliefs,
      :pcl_blaming,
      :pcl_negative_feelings,
      :pcl_loss_of_interest,
      :pcl_feeling_distant,
      :pcl_trouble_positive_feelings,
      :pcl_irritable_behavior,
      :pcl_risky_behavior,
      :pcl_super_alert,
      :pcl_jumpy,
      :pcl_difficulty_concentrating,
      :pcl_sleep_trouble,
      # Page 3: Impact Statement
      :statement
    )
  end

  # Sets focus context for AI chat when viewing this baseline
  def set_baseline_focus
    set_focus_context(:baseline, @baseline.id)
  end

  # Determines which section of the form to display
  def set_section
    @section = params[:section].presence_in(VALID_SECTIONS) || 'checklist'
  end
end
