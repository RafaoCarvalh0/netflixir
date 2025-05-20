defmodule NetflixirWeb.WatchLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos

  @impl true
  def mount(%{"id" => video_id}, _session, socket) do
    video = Videos.get_video_by_id!(video_id)
    {:ok, assign(socket, video: video)}
  end
end
