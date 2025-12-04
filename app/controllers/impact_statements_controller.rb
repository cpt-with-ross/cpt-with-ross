class ImpactStatementsController < ApplicationController

  # GET /impact_statements/1 or /impact_statements/1.json
  def show
    index_event = IndexEvent.find(params[:index_event_id])

    @impact_statement = index_event.impact_statement
  end

  # GET /impact_statements/1/edit
  def edit
    # @impact_statement = ImpactStatement.find(params[:id])
    index_event = IndexEvent.find(params[:index_event_id])

    @impact_statement = index_event.impact_statement
  end

  # PATCH/PUT /impact_statements/1 or /impact_statements/1.json
  def update
    index_event = IndexEvent.find(params[:index_event_id])
    @impact_statement = index_event.impact_statement

    respond_to do |format|
      if @impact_statement.update(impact_statement_params)
        format.html { redirect_to index_event_impact_statement_path(index_event), notice: "Impact statement was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @impact_statement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @impact_statement.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def impact_statement_params
      params.require(:impact_statement).permit(:content)
    end
end
