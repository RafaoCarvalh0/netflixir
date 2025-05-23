defmodule Netflixir.Videos.Services.VideoService do
  alias Netflixir.Storage
  alias Netflixir.Videos.Externals.VideoExternal

  @one_week_in_seconds 604_800
  @placeholder_image_path "/images/placeholder.jpg"
  @thumbnails_prefix "thumbnails/"

  defp processed_videos_prefix do
    Application.get_env(:netflixir, :processed_videos_prefix)
  end

  @spec list_available_videos() :: [VideoExternal.t()]
  def list_available_videos do
    case Storage.list_directories(processed_videos_prefix()) do
      {:ok, directories} ->
        directories
        |> Enum.map(&get_video_name/1)
        |> Task.async_stream(
          fn video_id ->
            get_video_info(video_id)
          end,
          max_concurrency: 10,
          timeout: :infinity
        )
        |> Enum.map(fn {:ok, video} -> video end)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  @spec get_video_by_id(String.t()) :: {:ok, VideoExternal.t()} | {:error, :not_found}
  def get_video_by_id(video_id) do
    directory = "#{processed_videos_prefix()}#{video_id}/"

    case Storage.list_files(directory) do
      {:ok, [%{key: _} | _]} ->
        {created_at, playlist_path, thumbnail} = get_video_external_attrs(directory, video_id)
        {:ok, VideoExternal.from_storage(video_id, created_at, playlist_path, thumbnail)}

      _ ->
        {:error, :not_found}
    end
  end

  defp get_video_external_attrs(directory, video_id) do
    {
      get_file_date(directory),
      get_playlist_path(video_id),
      get_thumbnail_url(video_id)
    }
  end

  defp get_video_name(storage_path) do
    prefix = processed_videos_prefix()

    if String.contains?(storage_path, prefix) do
      storage_path
      |> String.replace(prefix, "")
      |> String.split("/")
      |> List.first()
    else
      Path.basename(storage_path, "/")
    end
  end

  @spec get_file_date(String.t()) :: String.t() | nil
  defp get_file_date(storage_path) do
    case Storage.list_files(storage_path) do
      {:ok, [%{last_modified: last_modified} | _]} -> last_modified
      _ -> nil
    end
  end

  @spec get_signed_url(String.t()) :: String.t() | nil
  def get_signed_url(key) do
    case Storage.get_private_url(key) do
      {:ok, url} -> url
      {:error, _} -> nil
    end
  end

  defp get_playlist_path(video_id) do
    playlist_key = "#{processed_videos_prefix()}#{video_id}/hls/master.m3u8"
    get_signed_url(playlist_key)
  end

  @spec get_thumbnail_url(String.t()) :: String.t()
  defp get_thumbnail_url(video_id) do
    thumbnail_key = "#{@thumbnails_prefix}#{video_id}.webp"

    with {:ok, [%{size: size} | _]} <- Storage.list_files(thumbnail_key),
         {:ok, url} <- generate_cached_thumbnail_url(thumbnail_key, %{size: size}) do
      url
    else
      _ -> @placeholder_image_path
    end
  end

  defp generate_cached_thumbnail_url(key, file) do
    cache_hash = generate_cache_hash(file)
    Storage.get_cached_url(key, @one_week_in_seconds, cache_hash)
  end

  defp generate_cache_hash(file) do
    last_modified = Map.get(file, :last_modified, DateTime.utc_now())
    size = Map.get(file, :size, 0)

    :crypto.hash(:md5, "#{last_modified}#{size}")
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end

  defp get_video_info(video_id) do
    directory =
      "#{processed_videos_prefix()}#{video_id}/"

    case Storage.list_files(directory) do
      {:ok, [%{key: _} | _]} ->
        {created_at, playlist_path, thumbnail} = get_video_external_attrs(directory, video_id)
        VideoExternal.from_storage(video_id, created_at, playlist_path, thumbnail)

      _ ->
        nil
    end
  end
end
