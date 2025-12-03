class StuckPointsController < ApplicationController
  before_action :set_stuck_point, only: %i[ show edit update destroy ]

  # GET /stuck_points or /stuck_points.json
  def index
    @stuck_points = StuckPoint.all
  end

  # GET /stuck_points/1 or /stuck_points/1.json
  def show
  end

  # GET /stuck_points/new
  def new
    @stuck_point = StuckPoint.new
  end

  # GET /stuck_points/1/edit
  def edit
  end

  # POST /stuck_points or /stuck_points.json
  def create
    @stuck_point = StuckPoint.new(stuck_point_params)

    respond_to do |format|
      if @stuck_point.save
        format.html { redirect_to @stuck_point, notice: "Stuck point was successfully created." }
        format.json { render :show, status: :created, location: @stuck_point }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stuck_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stuck_points/1 or /stuck_points/1.json
  def update
    respond_to do |format|
      if @stuck_point.update(stuck_point_params)
        format.html { redirect_to @stuck_point, notice: "Stuck point was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @stuck_point }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stuck_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stuck_points/1 or /stuck_points/1.json
  def destroy
    @stuck_point.destroy!

    respond_to do |format|
      format.html { redirect_to stuck_points_path, notice: "Stuck point was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stuck_point
      @stuck_point = StuckPoint.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stuck_point_params
      params.require(:stuck_point,:title, :trauma_id, :belief, :belief_type).permit(:resolved)
    end
end
