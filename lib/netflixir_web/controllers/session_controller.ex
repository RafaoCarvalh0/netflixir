defmodule NetflixirWeb.SessionController do
  use NetflixirWeb, :controller

  alias NetflixirWeb.Auth

  def new(conn, _params) do
    render(conn, :login, error: nil, current_user: nil)
  end

  def create(conn, %{"user" => user_params}) do
    case Auth.authenticate_user(user_params) do
      {:ok, %{user: user}} ->
        conn
        |> put_session(:current_user, user)
        |> redirect(to: "/")

      {:error, error} when error in [:not_found, :invalid_password] ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> render(:login, error: "Invalid username or password", current_user: nil)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
