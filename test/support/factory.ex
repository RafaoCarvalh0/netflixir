defmodule Netflixir.Factory do
  use ExMachina.Ecto, repo: Netflixir.Repo

  alias Netflixir.Users.Stores.Schemas.User

  def user_factory(attrs) do
    password = Map.get(attrs, :password, "password123")

    %User{
      name: Map.get(attrs, :name, sequence(:name, &"User #{&1}")),
      email: Map.get(attrs, :email, sequence(:email, &"user#{&1}@example.com")),
      username: Map.get(attrs, :username, sequence(:username, &"user#{&1}")),
      password: password,
      password_hash: Bcrypt.hash_pwd_salt(password),
      created_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    }
  end

  def after_build(:user, user) do
    password = Map.get(user, :password, "password123")
    %{user | password_hash: Bcrypt.hash_pwd_salt(password)}
  end
end
