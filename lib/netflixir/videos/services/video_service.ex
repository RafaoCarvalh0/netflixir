defmodule Netflixir.Videos.Services.VideoService do
  alias Netflixir.Storage
  alias Netflixir.Videos.Externals.VideoExternal
  alias Netflixir.Videos.Stores.VideoStore
  alias Netflixir.Videos.Processors.ThumbnailProcessor
  alias Netflixir.Users.Services.UserService

  @submitted_videos_prefix "submitted_videos"
  # 50MB in bytes (for 1-minute videos)
  @max_video_size 50 * 1024 * 1024
  # 2MB in bytes
  @max_thumbnail_size 2 * 1024 * 1024

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

  @spec upload_submitted_video_and_thumbnail(binary(), binary(), String.t(), String.t()) ::
          {:ok, :success} | {:error, String.t()}
  def upload_submitted_video_and_thumbnail(
        video_binary,
        thumbnail_binary,
        file_name,
        username
      ) do
    with {:ok, :valid} <- validate_user_can_upload_more_videos(username),
         {:ok, :valid} <- validate_video_and_thumbnail(video_binary, thumbnail_binary),
         {:ok, sanitized_name} <- generate_filename(file_name),
         {:ok, video_storage_path} <- generate_video_storage_path(username, sanitized_name),
         {:ok, thumbnail_storage_path} <-
           generate_thumbnail_storage_path(username, sanitized_name),
         {:ok, thumbnail_binary} <- ThumbnailProcessor.thumbnail_from_binary(thumbnail_binary),
         {:ok, _video_url} <- Storage.upload_binary(video_binary, video_storage_path, false),
         {:ok, _thumbnail_url} <- Storage.upload_binary(thumbnail_binary, thumbnail_storage_path) do
      {:ok, :success}
    else
      {:error, reason} -> {:error, "Failed to upload video and thumbnail: #{inspect(reason)}"}
    end
  end

  defp validate_user_can_upload_more_videos(username) do
    if UserService.user_reached_video_upload_limit?(username) do
      {:error, "User has reached the maximum number of videos allowed"}
    else
      {:ok, :valid}
    end
  end

  defp validate_video_and_thumbnail(video_binary, thumbnail_binary) do
    with {:ok, :valid} <- validate_binary_size(video_binary, @max_video_size, "video"),
         {:ok, :valid} <-
           validate_binary_size(thumbnail_binary, @max_thumbnail_size, "thumbnail") do
      {:ok, :valid}
    end
  end

  defp validate_binary_size(binary, max_size, type) do
    binary_size = byte_size(binary)
    max_size_mb = max_size / (1024 * 1024)

    if binary_size <= max_size do
      {:ok, :valid}
    else
      {:error, "#{type} size exceeds maximum allowed size of #{max_size_mb}MB"}
    end
  end

  defp sanitize_filename(filename) do
    filename
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
    |> String.slice(0, 25)
  end

  defp generate_filename(filename) do
    sanitized = sanitize_filename(filename)
    minimum_length = 3
    valid_filename_pattern = ~r/^[a-z0-9_]+$/

    cond do
      String.length(sanitized) < minimum_length ->
        {:error, "Invalid filename: too short"}

      !String.match?(sanitized, valid_filename_pattern) ->
        {:error, "Invalid filename: contains invalid characters"}

      true ->
        {:ok, sanitized}
    end
  end

  defp generate_video_storage_path(file_directory, sanitized_name) do
    {:ok, "#{@submitted_videos_prefix}/#{file_directory}/#{sanitized_name}/#{sanitized_name}.mp4"}
  end

  defp generate_thumbnail_storage_path(file_directory, sanitized_name) do
    {:ok,
     "#{@submitted_videos_prefix}/#{file_directory}/#{sanitized_name}/#{sanitized_name}.webp"}
  end

  @spec list_submitted_videos_names_from_user(String.t()) :: [String.t()]
  def list_submitted_videos_names_from_user(username) do
    username
    |> VideoStore.fetch_user_videos_directories_by_username()
    |> Enum.map(&get_video_name/1)
  end

  defp get_video_name(path) do
    path
    |> String.split("/")
    |> Enum.filter(&(String.length(&1) > 0))
    |> List.last()
  end
end
