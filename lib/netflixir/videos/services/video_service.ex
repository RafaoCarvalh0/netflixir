defmodule Netflixir.Videos.Services.VideoService do
  alias Netflixir.Storage
  alias Netflixir.Videos.Externals.VideoExternal
  alias Netflixir.Videos.Stores.VideoStore

  @spec list_available_videos() :: [VideoExternal.t()]
  def list_available_videos do
    Enum.map(VideoStore.list_available_videos(), &build_video_external/1)
  end

  @spec get_video_by_id(String.t()) :: {:ok, VideoExternal.t()} | {:error, :not_found}
  def get_video_by_id(video_id) do
    case VideoStore.get_video_by_id(video_id) do
      {:ok, video} -> {:ok, build_video_external(video)}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  @spec get_signed_url(String.t()) :: String.t() | nil
  def get_signed_url(key) do
    case Storage.get_private_url(key) do
      {:ok, url} -> url
      {:error, _} -> nil
    end
  end

  defp build_video_external(video) do
    VideoExternal.from_storage(
      video.id,
      video.created_at,
      video.playlist_url,
      video.thumbnail_url
    )
  end
end
