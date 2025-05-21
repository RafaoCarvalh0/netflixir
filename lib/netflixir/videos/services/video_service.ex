defmodule Netflixir.Videos.Services.VideoService do
  alias Netflixir.Storage
  alias Netflixir.Videos.VideoConfig
  alias Netflixir.Videos.Externals.VideoExternal

  @processed_videos_prefix "processed_videos/"
  @thumbnails_prefix "thumbnails/"

  @spec list_available_videos() :: [VideoExternal.t()]
  def list_available_videos do
    case Storage.list_directories(VideoConfig.storage_bucket(), @processed_videos_prefix) do
      {:ok, directories} ->
        directories
        |> Task.async_stream(
          fn directory ->
            video_id = String.trim_trailing(Path.basename(directory), "/")
            created_at = get_file_date(directory)
            thumbnail_url = get_thumbnail_url(video_id)
            VideoExternal.from_storage(directory, created_at, thumbnail_url)
          end,
          max_concurrency: 10,
          timeout: :infinity
        )
        |> Enum.map(fn {:ok, video} -> video end)

      {:error, _reason} ->
        []
    end
  end

  @spec get_video_by_id(String.t()) :: {:ok, VideoExternal.t()} | {:error, :not_found}
  def get_video_by_id(video_id) do
    processed_key = "#{@processed_videos_prefix}#{video_id}/hls/master.m3u8"

    case Storage.list_files(VideoConfig.storage_bucket(), processed_key) do
      {:ok, [_ | _]} ->
        created_at = get_file_date(processed_key)
        thumbnail_url = get_thumbnail_url(video_id)
        {:ok, VideoExternal.from_storage(video_id, created_at, thumbnail_url)}

      _ ->
        {:error, :not_found}
    end
  end

  defp get_file_date(storage_path) do
    case Storage.list_files(VideoConfig.storage_bucket(), storage_path) do
      {:ok, [_ | _]} -> DateTime.utc_now() |> DateTime.to_string()
      _ -> nil
    end
  end

  defp get_thumbnail_url(video_id) do
    thumbnail_key = "#{@thumbnails_prefix}#{video_id}.jpg"

    case Storage.list_files(VideoConfig.storage_bucket(), thumbnail_key) do
      {:ok, [_ | _]} ->
        Storage.get_private_url(VideoConfig.storage_bucket(), thumbnail_key)

      _ ->
        "/images/placeholder.jpg"
    end
  end
end
