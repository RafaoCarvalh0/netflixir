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
        "name" => user.name,
        "email" => user.email,
        "username" => user.username,
        "created_at" => NaiveDateTime.to_iso8601(user.created_at),
        "updated_at" => NaiveDateTime.to_iso8601(user.updated_at)
      }

      assert json == expected
    end
  end
end
