defmodule Netflixir.Users.Externals.UserExternalTest do
  use ExUnit.Case, async: true
  import Netflixir.Factory

  alias Netflixir.Users.Externals.UserExternal

  describe "from_db/1" do
    test "converts a user struct to external representation" do
      user = build(:user)
      external = UserExternal.from_db(user)

      expected = %UserExternal{
        name: user.name,
        email: user.email,
        username: user.username,
        created_at: user.created_at,
        updated_at: user.updated_at
      }

      assert external == expected
    end

    test "serializes external struct to JSON with only public fields" do
      user = build(:user)
      external = UserExternal.from_db(user)

      json =
        external
        |> Jason.encode!()
        |> Jason.decode!()

      expected = %{
        "id" => nil,
        "name" => user.name,
        "email" => user.email,
        "username" => user.username,
        "created_at" => NaiveDateTime.to_iso8601(user.created_at),
        "updated_at" => NaiveDateTime.to_iso8601(user.updated_at)
      }

      assert json == expected
    end

    test "converts attrs map to UserExternal struct with id" do
      attrs = %{
        id: 123,
        name: "Test User",
        email: "test@example.com",
        username: "testuser",
        created_at: ~N[2024-06-01 12:00:00],
        updated_at: ~N[2024-06-01 12:00:00]
      }

      user = UserExternal.from_db(attrs)
      assert user.id == 123
      assert user.name == "Test User"
      assert user.email == "test@example.com"
      assert user.username == "testuser"
      assert user.created_at == ~N[2024-06-01 12:00:00]
      assert user.updated_at == ~N[2024-06-01 12:00:00]
    end

    test "serializes struct to JSON including id" do
      user = %UserExternal{
        id: 42,
        name: "Alice",
        email: "alice@email.com",
        username: "alice",
        created_at: ~N[2024-06-01 10:00:00],
        updated_at: ~N[2024-06-01 10:00:00]
      }

      json = Jason.encode!(user) |> Jason.decode!()
      assert json["id"] == 42
      assert json["name"] == "Alice"
      assert json["email"] == "alice@email.com"
      assert json["username"] == "alice"
      assert json["created_at"] == "2024-06-01T10:00:00"
      assert json["updated_at"] == "2024-06-01T10:00:00"
    end
  end
end
