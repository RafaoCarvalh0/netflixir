defmodule NetflixirWeb.WatchLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @impl true
  def mount(%{"id" => video_id}, _session, socket) do
    socket =
      socket
      |> assign_new(:video, fn ->
        case VideoService.get_video_by_id(video_id) do
          {:ok, video} -> video
          {:error, _} -> nil
        end
      end)
      |> assign_new(:current_quality, fn -> "auto" end)

    if socket.assigns.video do
      {:ok, socket}
    else
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
    url = VideoService.get_signed_url(path)
    {:reply, %{url: url}, socket}
  end
end
