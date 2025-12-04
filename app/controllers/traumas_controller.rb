class TraumasController < ApplicationController
  before_action :set_trauma, only: %i[ show edit update destroy ]

  # GET /traumas or /traumas.json
  def index
    @traumas = Trauma.all
  end

  # GET /traumas/1 or /traumas/1.json
  def show
  end

  # GET /traumas/new
  def new
    @trauma = Trauma.new
  end

  # GET /traumas/1/edit
  def edit
  end

  # POST /traumas or /traumas.json
  def create
    @trauma = Trauma.new(trauma_params)

    respond_to do |format|
      if @trauma.save
        format.html { redirect_to @trauma, notice: "Trauma was successfully created." }
        format.json { render :show, status: :created, location: @trauma }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @trauma.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /traumas/1 or /traumas/1.json
  def update
    respond_to do |format|
      if @trauma.update(trauma_params)
        format.html { redirect_to @trauma, notice: "Trauma was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @trauma }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @trauma.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /traumas/1 or /traumas/1.json
  def destroy
    @trauma.destroy!

    respond_to do |format|
      format.html { redirect_to traumas_path, notice: "Trauma was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trauma
      @trauma = Trauma.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def trauma_params
      params.require(:name).permit(:event_date, :user_id)
    end
end
