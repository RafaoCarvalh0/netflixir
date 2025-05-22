defmodule NetflixirWeb.WatchLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService
  alias Netflixir.Storage
  alias Netflixir.Videos.VideoConfig

  @impl true
  def mount(%{"id" => video_id}, _session, socket) do
    case VideoService.get_video_by_id(video_id) do
      {:ok, video} ->
        {:ok,
         socket
         |> assign(:video, video)
         |> assign(:current_quality, "auto")}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Video not found")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("change_quality", %{"quality" => quality}, socket) do
    {:noreply, assign(socket, :current_quality, quality)}
  end

  @impl true
  def handle_event("get_signed_url", %{"path" => path}, socket) do
    signed_url = Storage.get_private_url(VideoConfig.storage_bucket(), path)
    {:reply, %{url: signed_url}, socket}
  end
end
