# frozen_string_literal: true

# =============================================================================
# AlternativeThoughtsController - Managing Challenging Questions Worksheets
# =============================================================================
#
# Alternative Thoughts Worksheets guide users through cognitive restructuring
# by examining stuck points through exploring questions and thinking patterns,
# then developing more balanced alternative thoughts.
#
# Sections (matching PDF):
# - D. Exploring Thoughts: 7 questions to examine the stuck point
# - E. Thinking Patterns: 5 cognitive distortion patterns
# - F. Alternative Thought: New balanced thought with belief rating
# - G. Re-rate Stuck Point: Updated belief in original thought
# - H. Emotions After: Final emotional state after worksheet
#
class AlternativeThoughtsController < ApplicationController
  include InlineFormRenderable
  include StuckPointChildResource
  include Exportable

  SECTIONS = %w[exploring patterns alternative rerate emotions_after].freeze

  exportable :alternative_thought

  # rubocop:disable Rails/LexicallyScopedActionFilter -- export and share are defined in Exportable concern
  before_action :set_alternative_thought, only: %i[show edit update destroy export share]
  # rubocop:enable Rails/LexicallyScopedActionFilter
  before_action :set_thought_focus, only: %i[show edit]
  before_action :set_section, only: %i[edit]

  # Renders the show view within the main_content Turbo Frame
  def show
  end

  # Renders inline form for creating a new alternative thought
  def new
    @alternative_thought = @stuck_point.alternative_thoughts.build
    render_inline_form @alternative_thought,
                       url: stuck_point_alternative_thoughts_path(@stuck_point),
                       placeholder: 'Name your new Alternative Thoughts Worksheet (Optional)...',
                       frame_id: "new_at_frame_#{@stuck_point.id}",
                       attribute_name: :title
  end

  # Dual behavior based on requesting Turbo Frame:
  # - main_content: Full edit form in center panel (with section tabs)
  # - title_frame: Inline title edit in sidebar
  def edit
    if turbo_frame_request_id == 'main_content'
      render :edit
    else
      render_inline_form @alternative_thought,
                         url: alternative_thought_path(@alternative_thought),
                         placeholder: 'Name your new Alternative Thoughts Worksheet (Optional)...',
                         frame_id: dom_id(@alternative_thought, :title_frame),
                         attribute_name: :title
    end
  end

  # Creates a new alternative thought. On success:
  # 1. Appends to sidebar list
  # 2. Clears the inline form
  # 3. Shows the new thought in main content
  def create
    @alternative_thought = @stuck_point.alternative_thoughts.build(alternative_thought_params)

    if @alternative_thought.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append("at_list_#{@stuck_point.id}",
                              partial: 'shared/file_sidebar_item',
                              locals: { item: @alternative_thought, is_active: true }),
          turbo_stream.update("new_at_frame_#{@stuck_point.id}", ''),
          turbo_stream.update('main_content',
                              partial: 'alternative_thoughts/show_content',
                              locals: { alternative_thought: @alternative_thought,
                                        stuck_point: @stuck_point })
        ]
      end
    else
      render_inline_form @alternative_thought,
                         url: stuck_point_alternative_thoughts_path(@stuck_point),
                         placeholder: 'Name your new Alternative Thoughts Worksheet (Optional)...',
                         frame_id: "new_at_frame_#{@stuck_point.id}",
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  # Updates the alternative thought. Refreshes main content for full edit form
  # or sidebar rename when currently viewing this thought.
  def update
    if @alternative_thought.update(alternative_thought_params)
      respond_with_turbo_or_redirect do
        sidebar_rename = turbo_frame_request_id == dom_id(@alternative_thought, :title_frame)
        viewing_self = viewing_self?(alternative_thought_path(@alternative_thought))

        streams = [
          turbo_stream.replace(
            dom_id(@alternative_thought, :title_frame),
            partial: 'shared/file_sidebar_title',
            locals: { item: @alternative_thought, is_active: viewing_self }
          )
        ]

        # Update main content if: full edit form OR viewing this thought
        if !sidebar_rename || viewing_self
          streams << turbo_stream.update(
            'main_content',
            partial: 'alternative_thoughts/show_content',
            locals: { alternative_thought: @alternative_thought, stuck_point: @stuck_point }
          )
        end

        render turbo_stream: streams
      end
    else
      render_inline_form @alternative_thought,
                         url: alternative_thought_path(@alternative_thought),
                         placeholder: 'Name your new Alternative Thoughts Worksheet (Optional)...',
                         frame_id: dom_id(@alternative_thought, :title_frame),
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  # Deletes thought with fallback handling from StuckPointChildResource
  def destroy
    destroy_with_fallback(@alternative_thought, alternative_thought_path(@alternative_thought))
  end

  private

  # Finds alternative thought with authorization via join to current user
  # Authorization is implicit via join scoping to current_user
  def set_alternative_thought
    @alternative_thought = AlternativeThought.joins(stuck_point: { index_event: :user })
                                             .where(users: { id: current_user.id })
                                             .find(params[:id])
    raise ActiveRecord::RecordNotFound unless @alternative_thought

    @stuck_point = @alternative_thought.stuck_point
  end

  def alternative_thought_params
    params.require(:alternative_thought).permit(
      :title, :alternative_thought,
      # Section B: Stuck point belief
      :stuck_point_belief_before,
      # Section D: Exploring thoughts (7 questions)
      :exploring_evidence_against, :exploring_missing_info, :exploring_all_or_none,
      :exploring_focused_one_piece, :exploring_questionable_source,
      :exploring_confusing_probability, :exploring_feelings_or_facts,
      # Section E: Thinking patterns (5 patterns)
      :pattern_jumping_to_conclusions, :pattern_ignoring_important_parts,
      :pattern_oversimplifying, :pattern_mind_reading, :pattern_emotional_reasoning,
      # Section F: Alternative thought belief
      :alternative_thought_belief,
      # Section G: Re-rated stuck point
      :stuck_point_belief_after,
      # Section C & H: Emotions (jsonb)
      emotions_before: {},
      emotions_after: {}
    )
  end

  # Sets focus context for AI chat when viewing this alternative thought
  def set_thought_focus
    set_focus_context(:alternative_thought, @alternative_thought.id)
  end

  # Sets the current section for tabbed editing
  def set_section
    @section = params[:section].presence || 'exploring'
    @section = 'exploring' unless SECTIONS.include?(@section)
  end
end
