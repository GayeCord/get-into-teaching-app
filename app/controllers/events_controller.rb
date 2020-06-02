class EventsController < ApplicationController
  def index
    @events = GetIntoTeachingApi::Client.upcoming_events
    @event_search = Events::Search.new
  end

  def search
    @event_search = Events::Search.new(event_search_params)
    @events = @event_search.query_events

    render :index
  end

  def show
    @event = GetIntoTeachingApi::Client.event(params[:id])
  end

private

  def event_search_params
    params
      .require(Events::Search.model_name.param_key)
      .permit(:type, :distance, :postcode, :month)
  end
end
