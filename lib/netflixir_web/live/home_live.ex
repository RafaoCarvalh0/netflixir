# lib/netflixir_web/live/home_live.ex
defmodule NetflixirWeb.HomeLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, videos: VideoService.list_available_videos())}
  end
end
