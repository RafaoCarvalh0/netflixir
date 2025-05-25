defmodule NetflixirWeb.HelloLive do
  use NetflixirWeb, :live_view

  def mount(_params, session, socket) do
    current_user = Map.get(session, "current_user")

    {:ok,
     socket
     |> assign(:message, "Hello World!")
     |> assign(:current_user, current_user)}
  end
end
