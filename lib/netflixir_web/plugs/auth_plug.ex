defmodule NetflixirWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  alias NetflixirWeb.Auth.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    with token when is_binary(token) <- get_token_from_cookie(conn),
         {:ok, claims} <- Token.verify_token(token) do
      assign(conn, :current_user, claims)
    else
      _ ->
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: "/login")
        |> halt()
    end
  end

  defp get_token_from_cookie(conn) do
    conn.cookies["user_token"]
  end
end
