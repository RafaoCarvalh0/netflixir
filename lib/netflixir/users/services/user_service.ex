defmodule Netflixir.Users.Services.UserService do
  alias Netflixir.Users.Stores.UserStore
  alias Netflixir.Users.Externals.UserExternal
  alias Netflixir.Users.Inputs.UserInputs

  @spec register_user(UserInputs.register_user_input()) ::
          {:ok, UserExternal.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    case UserStore.create_user(attrs) do
      {:ok, user} -> {:ok, UserExternal.from_db(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @spec login_user(UserInputs.login_user_input()) ::
          {:ok, UserExternal.t()} | {:error, :not_found | :invalid_password}
  def login_user(%{username: username, password: password}) when is_binary(username) do
    case UserStore.get_user_by_username(username) do
      nil -> {:error, :not_found}
      user -> check_password(user, password)
    end
  end

  def login_user(%{email: email, password: password}) when is_binary(email) do
    case UserStore.get_user_by_email(email) do
      nil -> {:error, :not_found}
      user -> check_password(user, password)
    end
  end

  def login_user(_), do: {:error, :not_found}

  defp check_password(user, password) do
    if Bcrypt.verify_pass(password, user.password_hash) do
      {:ok, UserExternal.from_db(user)}
    else
      {:error, :invalid_password}
    end
  end
end
