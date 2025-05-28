defmodule Netflixir.Videos.Stores.VideoStore do
  @moduledoc """
  Store for videos.
  Responsible for handling data access and storage operations.
  Abstracts the underlying storage implementation from the service layer.
  """

  alias Netflixir.Storage

  @one_week_in_seconds 604_800
  @placeholder_image_path "/images/placeholder.jpg"

  @type video :: %{
          id: String.t(),
          thumbnail_url: String.t(),
          playlist_url: String.t(),
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @spec list_available_videos() :: [video()]
  def list_available_videos do
    case Storage.list_directories(processed_videos_prefix()) do
      {:ok, directories} ->
        directories
        |> Task.async_stream(
          fn path ->
            video_id = get_video_name(path)
            video_map(video_id)
          end,
          max_concurrency: 10,
          timeout: :infinity
        )
        |> Enum.map(fn {:ok, data} -> data end)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  @spec get_video_by_id(String.t()) :: {:ok, video()} | {:error, :not_found}
  def get_video_by_id(video_id) do
    case video_map(video_id) do
      nil -> {:error, :not_found}
      video -> {:ok, video}
    end
  end

  @spec fetch_user_videos_directories_by_username(String.t()) :: [String.t()]
  def fetch_user_videos_directories_by_username(username) do
    submitted_prefix = "submitted_videos/#{username}/"

    case Storage.list_directories(submitted_prefix) do
      {:ok, directories} ->
        directories

      _ ->
        []
    end
  end

  defp video_map(video_id, base_prefix \\ processed_videos_prefix()) do
    directory = "#{base_prefix}#{video_id}/"
    thumbnail_key = "thumbnails/#{video_id}.webp"
    playlist_key = "#{directory}hls/master.m3u8"

    with {:ok, [%{last_modified: last_modified} | _]} <- Storage.list_files(directory),
         {:ok, thumbnail_files} <- Storage.list_files(thumbnail_key) do
      thumbnail_url =
        case thumbnail_files do
          [%{size: size} | _] ->
            {:ok, url} = generate_cached_thumbnail_url(thumbnail_key, %{size: size})
            url

          _ ->
            @placeholder_image_path
        end

      %{
        id: video_id,
        created_at: last_modified,
        updated_at: last_modified,
        thumbnail_url: thumbnail_url,
        playlist_url: playlist_key
      }
    else
      _ -> nil
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

  defp processed_videos_prefix do
    Application.get_env(:netflixir, :processed_videos_prefix)
  end
end
