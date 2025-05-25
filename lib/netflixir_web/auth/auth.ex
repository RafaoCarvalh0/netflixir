defmodule NetflixirWeb.Auth do
  alias Netflixir.Users.Services.UserService
  alias NetflixirWeb.Auth.Token

  @spec authenticate_user(%{login: String.t(), password: String.t()}) ::
          {:ok, %{user: map(), token: String.t()}} | {:error, :not_found | :invalid_password}
  def authenticate_user(%{"login" => login, "password" => password})
      when is_binary(login) and is_binary(password) do
    with {:ok, user} <- get_user_by_login(login),
         {:ok, user_password_hash} <- UserService.get_password_hash_by_user_id(user.id),
         {:ok, :success} <- verify_password(password, user_password_hash),
         {:ok, token} <- Token.generate_token(user) do
      {:ok, %{user: user, token: token}}
    end
  end

  def authenticate_user(_), do: {:error, :not_found}

  defp get_user_by_login(login) do
    if is_email?(login) do
      UserService.get_user_by_email(login)
    else
      UserService.get_user_by_username(login)
    end
  end

  defp is_email?(login) do
    Regex.match?(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/, login)
  end

  defp verify_password(password, user_password_hash) do
    if Bcrypt.verify_pass(password, user_password_hash) do
      {:ok, :success}
    else
      {:error, :invalid_password}
    end
  end
end
