defmodule NetflixirWeb.SessionController do
  use NetflixirWeb, :controller

  def set_jwt(conn, %{"token" => token}) do
    conn
    |> put_resp_cookie("user_token", token,
      http_only: true,
      secure: true,
      max_age: 60 * 60 * 24 * 7
    )
    |> redirect(to: "/")
  end

  def logout(conn, _params) do
    conn
    |> delete_resp_cookie("user_token")
    |> clear_session()
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: "/")
  end
end
