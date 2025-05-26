defmodule NetflixirWeb.Plugs.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  alias NetflixirWeb.Auth.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    with token when not is_nil(token) <- get_session(conn, :user_token),
         {:ok, _claims} <- Token.verify_token(token) do
      conn
    else
      _ ->
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: "/login")
        |> halt()
    end
  end
end
