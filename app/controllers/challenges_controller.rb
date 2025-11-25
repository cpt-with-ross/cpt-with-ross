class ChallengesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_challenge, only: %i[show edit update destroy]

  # GET /challenges or /challenges.json
  def index
    @challenges = current_user.challenges
  end

  # GET /challenges/1 or /challenges/1.json
  def show
  end

  # GET /challenges/new
  def new
    @challenge = current_user.challenges.build
  end

  # GET /challenges/1/edit
  def edit
  end

  # POST /challenges or /challenges.json
  def create
    @challenge = current_user.challenges.build(challenge_params)

    respond_to do |format|
      if @challenge.save
        format.html { redirect_to @challenge, notice: 'Challenge was successfully created.' }
        format.json { render :show, status: :created, location: @challenge }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @challenge.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /challenges/1 or /challenges/1.json
  def update
    respond_to do |format|
      if @challenge.update(challenge_params)
        format.html { redirect_to @challenge, notice: 'Challenge was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @challenge }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @challenge.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /challenges/1 or /challenges/1.json
  def destroy
    @challenge.destroy!

    respond_to do |format|
      format.html { redirect_to challenges_path, notice: 'Challenge was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_challenge
    @challenge = current_user.challenges.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def challenge_params
    params.require(:challenge).permit(:title, :description)
  end
end
