class StuckPointsController < ApplicationController
  before_action :set_index_event, only: %i[ new create ]
  before_action :set_stuck_point, only: %i[ edit update destroy ]

  # GET /index_events/:index_event_id/stuck_points/new
  def new
    @stuck_point = @index_event.stuck_points.new
  end

  # GET /index_events/:index_event_id/stuck_points/:id/edit
  def edit
  end

  # POST /index_events/:index_event_id/stuck_points
  def create
    @stuck_point = @index_event.stuck_points.new(stuck_point_params)

    respond_to do |format|
      if @stuck_point.save
        format.html { redirect_to index_events_path, notice: "Stuck point was successfully created." }
        format.json { render :index, status: :created, location: index_event_stuck_points_path(@index_event) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stuck_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /index_events/:index_event_id/stuck_points/:id
  def update
    respond_to do |format|
      if @stuck_point.update(stuck_point_params)
        format.html { redirect_to index_events_path, notice: "Stuck point was successfully updated.", status: :see_other }
        format.json { render :index, status: :ok, location: index_event_stuck_points_path(@index_event) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stuck_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /index_events/:index_event_id/stuck_points/:id
  def destroy
    @stuck_point.destroy!

    respond_to do |format|
      format.html { redirect_to index_event_stuck_points_path(@index_event), notice: "Stuck point was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_index_event
      # Use find_by and render 404 for missing/invalid ids (including literal ":index_event_id")
      @index_event = IndexEvent.find_by(id: params[:index_event_id])
      unless @index_event
        render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_stuck_point
      @stuck_point = StuckPoint.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stuck_point_params
      params.require(:stuck_point).permit(:title, :belief, :belief_type, :resolved)
    end
end
