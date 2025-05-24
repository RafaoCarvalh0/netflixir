defmodule NetflixirWeb.HomeLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_new(socket, :videos, fn -> VideoService.list_available_videos() end)}
  end
end
