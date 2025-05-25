defmodule NetflixirWeb.Plugs.FetchCurrentUser do
  import Plug.Conn

  alias NetflixirWeb.Auth.Token

  def init(default), do: default

  def call(conn, _opts) do
    case fetch_cookies(conn) do
      %{cookies: %{"user_token" => token}} ->
        case Token.verify_token(token) do
          {:ok, user} ->
            put_session(conn, :current_user, user)

          _ ->
            conn
        end

      _ ->
        conn
    end
  end
end
