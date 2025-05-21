defmodule NetflixirWeb.WatchLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @impl true
  def mount(%{"id" => video_id}, _session, socket) do
    video = VideoService.get_video_by_id!(video_id)

    {:ok,
     socket
     |> assign(:video, video)
     |> assign(:current_quality, "auto")}
  end

  @impl true
  def handle_event("change_quality", %{"quality" => quality}, socket) do
    {:noreply, assign(socket, :current_quality, quality)}
  end
end
