class AbcWorksheetsController < ApplicationController
  include InlineFormRenderable

  before_action :set_stuck_point, only: %i[new create]
  before_action :set_abc_worksheet, only: %i[show edit update destroy]

  def show
  end

  def new
    @abc_worksheet = @stuck_point.abc_worksheets.build
    render_inline_form @abc_worksheet,
                       url: stuck_point_abc_worksheets_path(@stuck_point),
                       placeholder: 'ABC Worksheet Title...',
                       frame_id: "new_abc_frame_#{@stuck_point.id}",
                       attribute_name: :title,
                       hidden_fields: { beliefs: @stuck_point.statement }
  end

  def edit
    if turbo_frame_request_id == 'main_content'
      render :edit
    else
      render_inline_form @abc_worksheet,
                         url: abc_worksheet_path(@abc_worksheet),
                         placeholder: 'ABC Worksheet Title...',
                         frame_id: dom_id(@abc_worksheet, :title_frame),
                         attribute_name: :title
    end
  end

  def create
    @abc_worksheet = @stuck_point.abc_worksheets.build(abc_worksheet_params)

    if @abc_worksheet.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append("abc_list_#{@stuck_point.id}",
                              partial: 'shared/file_sidebar_item',
                              locals: { item: @abc_worksheet }),
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
                         placeholder: 'ABC Worksheet Title...',
                         frame_id: "new_abc_frame_#{@stuck_point.id}",
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  def update
    if @abc_worksheet.update(abc_worksheet_params)
      # Sync stuck point statement when beliefs changes
      @stuck_point.update(statement: @abc_worksheet.beliefs) if abc_worksheet_params[:beliefs].present?

      respond_with_turbo_or_redirect do
        streams = [
          turbo_stream.replace(
            dom_id(@abc_worksheet, :title_frame),
            partial: 'shared/file_sidebar_title',
            locals: { item: @abc_worksheet }
          ),
          turbo_stream.update(
            'main_content',
            partial: 'abc_worksheets/show_content',
            locals: { abc_worksheet: @abc_worksheet, stuck_point: @stuck_point }
          )
        ]

        # Update stuck point title in sidebar if beliefs changed
        if abc_worksheet_params[:beliefs].present?
          streams << turbo_stream.replace(
            dom_id(@stuck_point, :title_frame),
            partial: 'stuck_points/title_button',
            locals: { stuck_point: @stuck_point }
          )
        end

        render turbo_stream: streams
      end
    else
      render_inline_form @abc_worksheet,
                         url: abc_worksheet_path(@abc_worksheet),
                         placeholder: 'ABC Worksheet Title...',
                         frame_id: dom_id(@abc_worksheet, :title_frame),
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  def destroy
    index_event = @stuck_point.index_event
    viewing_self = params[:current_path] == abc_worksheet_path(@abc_worksheet)
    @abc_worksheet.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(@abc_worksheet))]

        if viewing_self
          streams << turbo_stream.update('main_content',
                                         partial: 'impact_statements/impact_statement',
                                         locals: { impact_statement: index_event.impact_statement })
        end

        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end

  private

  def set_stuck_point
    @stuck_point = StuckPoint.joins(index_event: :user)
                             .where(users: { id: current_user.id })
                             .find(params[:stuck_point_id])
  end

  def set_abc_worksheet
    @abc_worksheet = AbcWorksheet.joins(stuck_point: { index_event: :user })
                                 .where(users: { id: current_user.id })
                                 .find(params[:id])
    @stuck_point = @abc_worksheet.stuck_point
  end

  def abc_worksheet_params
    params.require(:abc_worksheet).permit(:title, :activating_event, :beliefs, :consequences)
  end
end
