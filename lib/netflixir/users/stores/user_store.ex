defmodule Netflixir.Users.Stores.UserStore do
  alias Netflixir.Repo
  alias Netflixir.Users.Stores.Schemas.User
  alias Netflixir.Users.Inputs.UserInputs

  @spec create_user(UserInputs.register_user_input()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  @spec get_user_by_username(String.t()) :: User.t() | nil
  def get_user_by_username(username), do: Repo.get_by(User, username: username)
end
