defmodule Netflixir.Factories.UserFactory do
  use ExMachina.Ecto, repo: Netflixir.Repo

  alias Netflixir.Users.Stores.Schemas.User

  defmacro __using__(_opts) do
    quote do
      def user_factory do
        %User{
          name: sequence(:name, &"User #{&1}"),
          email: sequence(:email, &"user#{&1}@example.com"),
          username: sequence(:username, &"user#{&1}"),
          password: "password123",
          password_hash: Bcrypt.hash_pwd_salt("password123"),
          created_at: NaiveDateTime.utc_now(),
          updated_at: NaiveDateTime.utc_now()
        }
      end
    end
  end
end
