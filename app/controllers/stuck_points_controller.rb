class StuckPointsController < ApplicationController
  before_action :set_trauma
  before_action :set_stuck_point, only: %i[ edit update destroy ]

  # GET /traumas/:trauma_id/stuck_points
  def index
    @stuck_points = @trauma.stuck_points
  end

  # GET /traumas/:trauma_id/stuck_points/new
  def new
    @stuck_point = @trauma.stuck_points.new
  end

  # GET /traumas/:trauma_id/stuck_points/:id/edit
  def edit
  end

  # POST /traumas/:trauma_id/stuck_points
  def create
    @stuck_point = @trauma.stuck_points.new(stuck_point_params)

    respond_to do |format|
      if @stuck_point.save
        format.html { redirect_to trauma_stuck_points_path(@trauma), notice: "Stuck point was successfully created." }
        format.json { render :index, status: :created, location: trauma_stuck_points_path(@trauma) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stuck_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /traumas/:trauma_id/stuck_points/:id
  def update
    respond_to do |format|
      if @stuck_point.update(stuck_point_params)
        format.html { redirect_to trauma_stuck_points_path(@trauma), notice: "Stuck point was successfully updated.", status: :see_other }
        format.json { render :index, status: :ok, location: trauma_stuck_points_path(@trauma) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stuck_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /traumas/:trauma_id/stuck_points/:id
  def destroy
    @stuck_point.destroy!

    respond_to do |format|
      format.html { redirect_to trauma_stuck_points_path(@trauma), notice: "Stuck point was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_trauma
      # Use find_by and render 404 for missing/invalid ids (including literal ":trauma_id")
      @trauma = Trauma.find_by(id: params[:trauma_id])
      unless @trauma
        render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_stuck_point
      @stuck_point = @trauma.stuck_points.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stuck_point_params
      params.require(:stuck_point).permit(:title, :belief, :belief_type, :resolved)
    end
end
