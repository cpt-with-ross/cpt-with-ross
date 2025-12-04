class IndexEventsController < ApplicationController
  before_action :set_index_event, only: %i[ show edit update destroy ]

  # GET /index_events or /index_events.json
  def index
    @index_events = current_user.index_events.order(created_at: :desc)
  end

  # GET /index_events/new
  def new
    @index_event = current_user.index_events.build
  end

  # GET /index_events/1/edit
  def edit
  end

  # POST /index_events or /index_events.json
  def create
    @index_event = current_user.index_events.build(index_event_params)
    @impact_statement = ImpactStatement.new(impact_statement_params)
    @impact_statement.index_event = @index_event # this set index_event inside the impact_statement

    respond_to do |format|
      if @index_event.save
        format.html { redirect_to index_events_path, notice: "IndexEvent logged successfully. Please write your impact statement." }
        format.json { render :show, status: :created, location: @index_event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @index_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /index_events/1 or /index_events/1.json
  def update
    respond_to do |format|
      if @index_event.update(index_event_params)
        format.html { redirect_to @index_event, notice: "IndexEvent was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @index_event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @index_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /index_events/1 or /index_events/1.json
  def destroy
    @index_event.destroy!

    respond_to do |format|
      format.html { redirect_to index_events_path, notice: "IndexEvent was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_index_event
      @index_event = current_user.index_events.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def index_event_params
      # user_id removed to prevent injection, ruby .build takes care of the user_id
      params.require(:index_event).permit(:name, :event_date)
    end

    def impact_statement_params
      params.require(:impact_statement).permit(:content)
    end
end
