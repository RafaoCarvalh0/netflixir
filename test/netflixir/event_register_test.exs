defmodule Netflixir.EventRegisterTest do
  use ExUnit.Case, async: true
  alias Netflixir.EventRegister

  describe "register_event/2" do
    test "registers a new event for an identifier" do
      identifier = "upload_123"
      event_type = :upload

      EventRegister.register_event(identifier, event_type)
      events = EventRegister.get_events_by_identifier(identifier)

      assert [{type, timestamp}] = events
      assert type == event_type
      assert %DateTime{} = timestamp
    end

    test "registers multiple events for the same identifier" do
      identifier = "process_456"

      EventRegister.register_event(identifier, :started)
      EventRegister.register_event(identifier, :processing)
      EventRegister.register_event(identifier, :completed)

      events = EventRegister.get_events_by_identifier(identifier)

      assert [
               {:completed, completed_timestamp},
               {:processing, processing_timestamp},
               {:started, started_timestamp}
             ] = events

      assert %DateTime{} = completed_timestamp
      assert %DateTime{} = processing_timestamp
      assert %DateTime{} = started_timestamp
      assert DateTime.compare(completed_timestamp, processing_timestamp) == :gt
      assert DateTime.compare(processing_timestamp, started_timestamp) == :gt
    end

    test "works with integer identifiers" do
      identifier = 123
      EventRegister.register_event(identifier, :created)
      events = EventRegister.get_events_by_identifier(identifier)
      assert [{:created, timestamp}] = events
      assert %DateTime{} = timestamp
    end

    test "works with atom identifiers" do
      identifier = :process_123
      EventRegister.register_event(identifier, :started)
      events = EventRegister.get_events_by_identifier(identifier)
      assert [{:started, timestamp}] = events
      assert %DateTime{} = timestamp
    end

    test "works with tuple identifiers" do
      identifier = {:user, 123}
      EventRegister.register_event(identifier, :login)
      events = EventRegister.get_events_by_identifier(identifier)
      assert [{:login, timestamp}] = events
      assert %DateTime{} = timestamp
    end
  end

  describe "get_events_by_identifier/1" do
    test "returns empty list for identifier with no events" do
      events = EventRegister.get_events_by_identifier("nonexistent_identifier")
      assert events == []
    end

    test "returns all events for an identifier in chronological order" do
      identifier = "job_789"

      EventRegister.register_event(identifier, :queued)
      EventRegister.register_event(identifier, :running)
      EventRegister.register_event(identifier, :finished)

      events = EventRegister.get_events_by_identifier(identifier)

      assert [
               {:finished, finished_timestamp},
               {:running, running_timestamp},
               {:queued, queued_timestamp}
             ] = events

      assert %DateTime{} = finished_timestamp
      assert %DateTime{} = running_timestamp
      assert %DateTime{} = queued_timestamp
      assert DateTime.compare(finished_timestamp, running_timestamp) == :gt
      assert DateTime.compare(running_timestamp, queued_timestamp) == :gt
    end
  end

  describe "get_events_between_dates/3" do
    test "returns events between specified dates" do
      identifier = "task_101"
      now = DateTime.utc_now()
      start_date = DateTime.add(now, -1, :hour)
      end_date = DateTime.add(now, 1, :hour)

      EventRegister.register_event(identifier, :created)
      EventRegister.register_event(identifier, :updated)

      events =
        EventRegister.get_events_between_dates(identifier, start_date, end_date)

      assert [
               {:updated, updated_timestamp},
               {:created, created_timestamp}
             ] = events

      assert %DateTime{} = updated_timestamp
      assert %DateTime{} = created_timestamp
      assert DateTime.compare(updated_timestamp, created_timestamp) == :gt
      assert DateTime.compare(updated_timestamp, start_date) != :lt
      assert DateTime.compare(updated_timestamp, end_date) != :gt
      assert DateTime.compare(created_timestamp, start_date) != :lt
      assert DateTime.compare(created_timestamp, end_date) != :gt
    end

    test "returns empty list when no events in date range" do
      identifier = "session_202"
      now = DateTime.utc_now()
      past_date = DateTime.add(now, -2, :hour)
      future_date = DateTime.add(now, -1, :hour)

      EventRegister.register_event(identifier, :login)

      events =
        EventRegister.get_events_between_dates(identifier, past_date, future_date)

      assert events == []
    end
  end

  describe "delete_events/1" do
    test "deletes all events for an identifier" do
      identifier = "document_303"

      EventRegister.register_event(identifier, :created)
      EventRegister.register_event(identifier, :modified)

      events = EventRegister.get_events_by_identifier(identifier)

      assert [
               {:modified, _modified_timestamp},
               {:created, _created_timestamp}
             ] = events

      EventRegister.delete_events(identifier)

      assert EventRegister.get_events_by_identifier(identifier) == []
    end

    test "handles deletion of non-existent identifier" do
      identifier = "nonexistent_identifier"

      EventRegister.delete_events(identifier)
      assert EventRegister.get_events_by_identifier(identifier) == []
    end
  end
end
