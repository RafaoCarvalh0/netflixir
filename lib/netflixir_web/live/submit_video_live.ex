defmodule NetflixirWeb.SubmitVideoLive do
  use NetflixirWeb, :live_view

  def mount(_params, session, socket) do
    current_user = Map.get(session, "current_user")

    {:ok, assign(socket, :current_user, current_user)}
  end
end
