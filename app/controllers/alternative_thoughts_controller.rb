# frozen_string_literal: true

# =============================================================================
# AlternativeThoughtsController - Managing Balanced Thought Challenges
# =============================================================================
#
# Alternative Thoughts are a CPT tool for cognitive restructuring. Once a stuck
# point is identified and analyzed via ABC worksheets, users create alternative
# thoughts that challenge and balance the original belief.
#
# Structure:
# - Unbalanced Thought: The original stuck point / automatic thought
# - Balanced Thought: A more realistic, helpful perspective
#
# This helps users move from all-or-nothing thinking (e.g., "I can never trust
# anyone") to balanced perspectives (e.g., "While some people have hurt me,
# I can learn to evaluate trustworthiness over time").
#
class AlternativeThoughtsController < ApplicationController
  include InlineFormRenderable
  include StuckPointChildResource

  before_action :set_alternative_thought, only: %i[show edit update destroy]

  # Renders the show view within the main_content Turbo Frame
  def show
  end

  # Renders inline form for creating a new alternative thought
  def new
    @alternative_thought = @stuck_point.alternative_thoughts.build
    render_inline_form @alternative_thought,
                       url: stuck_point_alternative_thoughts_path(@stuck_point),
                       placeholder: 'Alternative Thought Title...',
                       frame_id: "new_at_frame_#{@stuck_point.id}",
                       attribute_name: :title
  end

  # Dual behavior based on requesting Turbo Frame:
  # - main_content: Full edit form in center panel
  # - title_frame: Inline title edit in sidebar
  def edit
    if turbo_frame_request_id == 'main_content'
      render :edit
    else
      render_inline_form @alternative_thought,
                         url: alternative_thought_path(@alternative_thought),
                         placeholder: 'Alternative Thought Title...',
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
                              locals: { item: @alternative_thought }),
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
                         placeholder: 'Alternative Thought Title...',
                         frame_id: "new_at_frame_#{@stuck_point.id}",
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  # Updates the alternative thought and refreshes both sidebar and main content
  def update
    if @alternative_thought.update(alternative_thought_params)
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@alternative_thought, :title_frame),
            partial: 'shared/file_sidebar_title',
            locals: { item: @alternative_thought }
          ),
          turbo_stream.update(
            'main_content',
            partial: 'alternative_thoughts/show_content',
            locals: { alternative_thought: @alternative_thought, stuck_point: @stuck_point }
          )
        ]
      end
    else
      render_inline_form @alternative_thought,
                         url: alternative_thought_path(@alternative_thought),
                         placeholder: 'Alternative Thought Title...',
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
  def set_alternative_thought
    @alternative_thought = AlternativeThought.joins(stuck_point: { index_event: :user })
                                             .where(users: { id: current_user.id })
                                             .find(params[:id])
    @stuck_point = @alternative_thought.stuck_point
  end

  def alternative_thought_params
    params.require(:alternative_thought).permit(:title, :unbalanced_thought, :balanced_thought)
  end
end
