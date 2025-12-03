class AbcWorksheetsController < ApplicationController
  before_action :set_abc_worksheet, only: %i[ show edit update destroy ]

  # GET /abc_worksheets or /abc_worksheets.json
  def index
    @abc_worksheets = AbcWorksheet.all
  end

  # GET /abc_worksheets/1 or /abc_worksheets/1.json
  def show
  end

  # GET /abc_worksheets/new
  def new
    @abc_worksheet = AbcWorksheet.new
  end

  # GET /abc_worksheets/1/edit
  def edit
  end

  # POST /abc_worksheets or /abc_worksheets.json
  def create
    @abc_worksheet = AbcWorksheet.new(abc_worksheet_params)

    respond_to do |format|
      if @abc_worksheet.save
        format.html { redirect_to @abc_worksheet, notice: "Abc worksheet was successfully created." }
        format.json { render :show, status: :created, location: @abc_worksheet }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @abc_worksheet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /abc_worksheets/1 or /abc_worksheets/1.json
  def update
    respond_to do |format|
      if @abc_worksheet.update(abc_worksheet_params)
        format.html { redirect_to @abc_worksheet, notice: "Abc worksheet was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @abc_worksheet }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @abc_worksheet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /abc_worksheets/1 or /abc_worksheets/1.json
  def destroy
    @abc_worksheet.destroy!

    respond_to do |format|
      format.html { redirect_to abc_worksheets_path, notice: "Abc worksheet was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_abc_worksheet
      @abc_worksheet = AbcWorksheet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def abc_worksheet_params
      params.require(:abc_worksheet).permit(:stuck_point_id, :activating_event, :consequence_feeling, :feeling_intensity, :consequence_behaviour)
    end
end
