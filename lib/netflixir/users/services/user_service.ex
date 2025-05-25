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

  @spec get_user_by_username(String.t()) :: {:ok, UserExternal.t()} | {:error, :not_found}
  def get_user_by_username(username) when is_binary(username) do
    case UserStore.get_user_by_username(username) do
      nil -> {:error, :not_found}
      user -> {:ok, UserExternal.from_db(user)}
    end
  end

  @spec get_user_by_email(String.t()) :: {:ok, UserExternal.t()} | {:error, :not_found}
  def get_user_by_email(email) when is_binary(email) do
    case UserStore.get_user_by_email(email) do
      nil -> {:error, :not_found}
      user -> {:ok, UserExternal.from_db(user)}
    end
  end

  @spec get_password_hash_by_user_id(non_neg_integer()) ::
          {:ok, String.t()} | {:error, :hash_not_found}
  def get_password_hash_by_user_id(id) do
    case UserStore.get_user_by_id(id) do
      user when is_binary(user.password_hash) -> {:ok, user.password_hash}
      _ -> {:error, :hash_not_found}
    end
  end
end
