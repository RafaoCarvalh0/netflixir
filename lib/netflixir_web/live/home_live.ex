# lib/netflixir_web/live/home_live.ex
defmodule NetflixirWeb.HomeLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos

  @impl true
  def mount(_params, _session, socket) do
    videos = Videos.list_available_videos()
    {:ok, assign(socket, videos: videos)}
  end
end
