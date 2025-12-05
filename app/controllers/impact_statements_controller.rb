class ImpactStatementsController < ApplicationController
  include InlineFormRenderable

  before_action :set_index_event
  before_action :set_impact_statement

  def show
  end

  def edit
  end

  def update
    if @impact_statement.update(impact_statement_params)
      redirect_to index_event_impact_statement_path(@index_event)
    else
      render :edit, status: :unprocessable_content
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
