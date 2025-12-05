class ImpactStatementsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event
  before_action :set_impact_statement

  def show
  end

  def edit
    render_inline_form @impact_statement,
                       url: index_event_impact_statement_path(@index_event),
                       placeholder: 'Write your impact statement...',
                       frame_id: dom_id(@impact_statement, :edit_frame),
                       attribute_name: :statement
  end

  def update
    if @impact_statement.update(impact_statement_params)
      respond_with_turbo_or_redirect do
        render turbo_stream: turbo_stream.replace(
          dom_id(@impact_statement),
          partial: 'impact_statements/impact_statement',
          locals: { impact_statement: @impact_statement }
        )
      end
    else
      render_inline_form @impact_statement,
                         url: index_event_impact_statement_path(@index_event),
                         placeholder: 'Write your impact statement...',
                         frame_id: dom_id(@impact_statement, :edit_frame),
                         attribute_name: :statement,
                         status: :unprocessable_content
    end
  end

  private

  def set_index_event
    @index_event = current_user.index_events.find(params[:index_event_id])
  end

  def set_impact_statement
    @impact_statement = @index_event.impact_statement
  end

  def impact_statement_params
    params.require(:impact_statement).permit(:statement)
  end
end
