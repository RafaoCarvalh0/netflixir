defmodule NetflixirWeb.Plugs.FetchCurrentUser do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :current_user) do
      nil ->
        assign(conn, :current_user, nil)

      user ->
        assign(conn, :current_user, user)
    end
  end
end
