class EventsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]


  def index
    @events = Event.where(visibility: true).bonzo(params[:page]).per(6)
    if params[:query].present?
      sql_subquery = <<~SQL
        events.title ilike :query
        OR events.description ilike :query
        OR types.name ilike :query
      SQL
      @events = @events.joins(:type).where(sql_subquery, query: "%#{params[:query]}%")
    end
  end

  def show
    @event = Event.find(params[:id])
    if current_user == @event.user
      @participants = @event.participations.where(status: 'approved')
      @pending_participations = @event.participations.where(status: 'pending')
    end
  end

  def new
    @event = Event.new
    @types = Type.all
  end

  def edit
    # @event is already set by the before_action
  end

  def create
    @event = Event.new(event_params)
    @event.user = current_user
    if @event.save
      redirect_to events_url, notice: 'Event was successfully created.'
    else
      render :new, alert: @event.errors.full_messages
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to event_url(@event), notice: 'Event was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
    end
  end


  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :description, :city, :capacity, :date, :address, :type_id)
  end
end
