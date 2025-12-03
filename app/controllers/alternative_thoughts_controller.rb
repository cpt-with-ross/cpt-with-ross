class AlternativeThoughtsController < ApplicationController
  before_action :set_alternative_thought, only: %i[ show edit update destroy ]

  # GET /alternative_thoughts or /alternative_thoughts.json
  def index
    @alternative_thoughts = AlternativeThought.all
  end

  # GET /alternative_thoughts/1 or /alternative_thoughts/1.json
  def show
  end

  # GET /alternative_thoughts/new
  def new
    @alternative_thought = AlternativeThought.new
  end

  # GET /alternative_thoughts/1/edit
  def edit
  end

  # POST /alternative_thoughts or /alternative_thoughts.json
  def create
    @alternative_thought = AlternativeThought.new(alternative_thought_params)

    respond_to do |format|
      if @alternative_thought.save
        format.html { redirect_to @alternative_thought, notice: "Alternative thought was successfully created." }
        format.json { render :show, status: :created, location: @alternative_thought }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @alternative_thought.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /alternative_thoughts/1 or /alternative_thoughts/1.json
  def update
    respond_to do |format|
      if @alternative_thought.update(alternative_thought_params)
        format.html { redirect_to @alternative_thought, notice: "Alternative thought was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @alternative_thought }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @alternative_thought.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /alternative_thoughts/1 or /alternative_thoughts/1.json
  def destroy
    @alternative_thought.destroy!

    respond_to do |format|
      format.html { redirect_to alternative_thoughts_path, notice: "Alternative thought was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_alternative_thought
      @alternative_thought = AlternativeThought.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def alternative_thought_params
      params.require(:alternative_thought).permit(:stuck_point_id, :evidence_for, :evidence_against, :alternative_thought, :belief_rating)
    end
end
