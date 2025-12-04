class ImpactStatementsController < ApplicationController
  before_action :set_impact_statement, only: %i[ show edit update destroy ]

  # GET /impact_statements or /impact_statements.json
  def index
    @impact_statements = ImpactStatement.all
  end

  # GET /impact_statements/1 or /impact_statements/1.json
  def show
  end

  # GET /impact_statements/new
  def new
    @trauma = Trauma.find(params[:trauma_id]) #params[:trauma_id] comes from the URL /traumas/:trauma_id/impact_statements/new
    @impact_statement = ImpactStatement.new
  end

  # GET /impact_statements/1/edit
  def edit
    # @impact_statement = ImpactStatement.find(params[:id])
  end

  # POST /impact_statements or /impact_statements.json
  def create
    @trauma = current_user.traumas.find(params[:trauma_id])
    @impact_statement = ImpactStatement.new(impact_statement_params)
    @impact_statement.trauma = @trauma # this set trauma inside the impact_statement

    respond_to do |format|
      if @impact_statement.save
        format.html { redirect_to traumas_path, notice: "Impact statement was successfully created." }
        format.json { render :show, status: :created, location: @impact_statement }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @impact_statement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /impact_statements/1 or /impact_statements/1.json
  def update
    respond_to do |format|
      if @impact_statement.update(impact_statement_params)
        format.html { redirect_to @impact_statement, notice: "Impact statement was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @impact_statement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @impact_statement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /impact_statements/1 or /impact_statements/1.json
  def destroy
    @impact_statement.destroy!

    respond_to do |format|
      format.html { redirect_to impact_statement_path, notice: "Impact statement was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_impact_statement
      @impact_statement = ImpactStatement.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def impact_statement_params
      params.require(:impact_statement).permit(:content)
    end
end
