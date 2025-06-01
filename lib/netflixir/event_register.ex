defmodule Netflixir.EventRegister do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def register_event(event_identifier, event_type) do
    GenServer.cast(__MODULE__, {:register_event, event_identifier, event_type})
  end

  def get_events_by_identifier(event_identifier) do
    GenServer.call(__MODULE__, {:get_events_by_identifier, event_identifier})
  end

  def get_events_between_dates(event_identifier, start_date, end_date) do
    GenServer.call(
      __MODULE__,
      {:get_events_between_dates, event_identifier, start_date, end_date}
    )
  end

  def delete_events(event_identifier) do
    GenServer.cast(__MODULE__, {:delete_events, event_identifier})
  end

  @impl true
  def handle_cast({:register_event, event_identifier, event_type}, state) do
    events = Map.get(state, event_identifier, [])
    updated_events = [{event_type, DateTime.utc_now()} | events]
    new_state = Map.put(state, event_identifier, updated_events)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:delete_events, event_identifier}, state) do
    new_state = Map.delete(state, event_identifier)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get_events_by_identifier, event_identifier}, _from, state) do
    events = Map.get(state, event_identifier, [])

    {:reply, events, state}
  end

  @impl true
  def handle_call(
        {:get_events_between_dates, event_identifier, start_date, end_date},
        _from,
        state
      ) do
    events = Map.get(state, event_identifier, [])

    filtered_events =
      Enum.filter(events, fn {_type, timestamp} ->
        DateTime.compare(timestamp, start_date) != :lt and
          DateTime.compare(timestamp, end_date) != :gt
      end)

    {:reply, filtered_events, state}
  end
end
