defmodule NetflixirWeb.HomeLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @impl true
  def mount(_params, session, socket) do
    current_user = Map.get(session, "current_user")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:videos, VideoService.list_available_videos())}
  end
end
