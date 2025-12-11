# frozen_string_literal: true

# =============================================================================
# AbcWorksheetsController - Managing A-B-C Cognitive Analysis Worksheets
# =============================================================================
#
# ABC Worksheets are a core CPT tool for identifying cognitive patterns:
# - A (Activating Event): The trigger situation
# - B (Beliefs): The stuck point / automatic thought
# - C (Consequences): Emotional and behavioral outcomes
#
# By breaking down situations this way, users can see how beliefs (not events)
# drive their emotional responses, which is key to cognitive restructuring.
#
# Bidirectional Sync:
# The worksheet's "beliefs" field mirrors the parent stuck point's statement.
# When beliefs are updated here, we sync back to the stuck point.
#
class AbcWorksheetsController < ApplicationController
  include InlineFormRenderable
  include StuckPointChildResource
  include Exportable

  exportable :abc_worksheet

  # rubocop:disable Rails/LexicallyScopedActionFilter -- export and share are defined in Exportable concern
  before_action :set_abc_worksheet, only: %i[show edit update destroy export share]
  # rubocop:enable Rails/LexicallyScopedActionFilter
  before_action :set_worksheet_focus, only: %i[show edit]

  # Renders the show view within the main_content Turbo Frame
  def show
  end

  # Renders inline form for creating a new worksheet.
  # Pre-fills beliefs with the stuck point statement for consistency.
  def new
    @abc_worksheet = @stuck_point.abc_worksheets.build
    render_inline_form @abc_worksheet,
                       url: stuck_point_abc_worksheets_path(@stuck_point),
                       placeholder: 'Name your new ABC Worksheet (Optional)...',
                       frame_id: "new_abc_frame_#{@stuck_point.id}",
                       attribute_name: :title,
                       hidden_fields: { beliefs: @stuck_point.statement }
  end

  # Dual behavior based on which Turbo Frame requested the action:
  # - main_content: Render full edit form in center panel
  # - title_frame: Render inline title edit in sidebar
  def edit
    if turbo_frame_request_id == 'main_content'
      render :edit
    else
      render_inline_form @abc_worksheet,
                         url: abc_worksheet_path(@abc_worksheet),
                         placeholder: 'Name your new ABC Worksheet (Optional)...',
                         frame_id: dom_id(@abc_worksheet, :title_frame),
                         attribute_name: :title
    end
  end

  # Creates a new ABC worksheet. On success:
  # 1. Appends to sidebar list
  # 2. Clears the inline form
  # 3. Shows the new worksheet in main content
  def create
    @abc_worksheet = @stuck_point.abc_worksheets.build(abc_worksheet_params)

    if @abc_worksheet.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append("abc_list_#{@stuck_point.id}",
                              partial: 'shared/file_sidebar_item',
                              locals: { item: @abc_worksheet, is_active: true }),
          turbo_stream.update("new_abc_frame_#{@stuck_point.id}", ''),
          turbo_stream.update('main_content',
                              partial: 'abc_worksheets/show_content',
                              locals: { abc_worksheet: @abc_worksheet,
                                        stuck_point: @stuck_point })
        ]
      end
    else
      render_inline_form @abc_worksheet,
                         url: stuck_point_abc_worksheets_path(@stuck_point),
                         placeholder: 'Name your new ABC Worksheet (Optional)...',
                         frame_id: "new_abc_frame_#{@stuck_point.id}",
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  # Updates the worksheet. Syncs beliefs back to the parent stuck point
  # to maintain consistency across the data model.
  def update
    if @abc_worksheet.update(abc_worksheet_params)
      # Bidirectional sync: Update stuck point and all sibling ABC worksheets
      @stuck_point.update(statement: @abc_worksheet[:beliefs])
      @stuck_point.sync_beliefs_to_worksheets(except_id: @abc_worksheet.id)

      respond_with_turbo_or_redirect do
        sidebar_rename = turbo_frame_request_id == dom_id(@abc_worksheet, :title_frame)
        viewing_self = viewing_self?(abc_worksheet_path(@abc_worksheet))

        streams = [
          turbo_stream.replace(
            dom_id(@abc_worksheet, :title_frame),
            partial: 'shared/file_sidebar_title',
            locals: { item: @abc_worksheet, is_active: viewing_self }
          )
        ]

        # Update main content if: full edit form OR viewing this worksheet
        if !sidebar_rename || viewing_self
          streams << turbo_stream.update(
            'main_content',
            partial: 'abc_worksheets/show_content',
            locals: { abc_worksheet: @abc_worksheet, stuck_point: @stuck_point }
          )
        end

        # Always update stuck point in sidebar to reflect beliefs changes
        streams << turbo_stream.replace(
          dom_id(@stuck_point, :title_frame),
          partial: 'stuck_points/title_button',
          locals: { stuck_point: @stuck_point }
        )

        render turbo_stream: streams
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deletes worksheet with fallback handling from StuckPointChildResource
  def destroy
    destroy_with_fallback(@abc_worksheet, abc_worksheet_path(@abc_worksheet))
  end

  private

  # Finds worksheet with authorization via join to current user
  # Authorization is implicit via join scoping to current_user
  def set_abc_worksheet
    @abc_worksheet = AbcWorksheet.joins(stuck_point: { index_event: :user })
                                 .where(users: { id: current_user.id })
                                 .find(params[:id])
    raise ActiveRecord::RecordNotFound unless @abc_worksheet

    @stuck_point = @abc_worksheet.stuck_point
  end

  def abc_worksheet_params
    permitted = params.require(:abc_worksheet).permit(:title, :activating_event, :beliefs, :consequences,
                                                      emotions: AbcWorksheet::EMOTIONS)

    # Convert emotions hash {emotion: intensity} to array [{emotion:, intensity:}]
    if permitted[:emotions].present?
      emotions_array = permitted[:emotions].to_h.filter_map do |emotion, intensity|
        int_val = intensity.to_i
        { 'emotion' => emotion, 'intensity' => int_val } if int_val.positive?
      end
      permitted[:emotions] = emotions_array
    end

    permitted
  end

  # Sets focus context for AI chat when viewing this worksheet
  def set_worksheet_focus
    set_focus_context(:abc_worksheet, @abc_worksheet.id)
  end
end
