# lib/netflixir_web/live/home_live.ex
defmodule NetflixirWeb.HomeLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @impl true
  def mount(_params, _session, socket) do
    videos = VideoService.list_available_videos()

    videos_with_thumbnails =
      Enum.map(videos, fn video ->
        Map.put(video, :thumbnail_path, get_thumbnail_path(video.id))
      end)

    {:ok, assign(socket, videos: videos_with_thumbnails)}
  end

  defp get_thumbnail_path(video_id) do
    thumbnail_path = Path.join(["priv", "static", "videos", "thumbnails", "#{video_id}.jpg"])

    if File.exists?(thumbnail_path) do
      "/videos/thumbnails/#{video_id}.jpg"
    else
      "/images/placeholder.jpg"
    end
  end
end
