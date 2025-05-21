defmodule Netflixir.Videos.RawVideoDownloader do
  @moduledoc """
  Module responsible for downloading raw videos from storage to local directory.
  Downloads are stored in the configured raw_videos_local_path and can overwrite existing files.
  """

  alias Netflixir.Storage
  alias Netflixir.Utils.DirectoryAndFileUtils
  alias Netflixir.Videos.VideoConfig

  @type raw_video_local_path :: String.t()

  @raw_videos_prefix "raw_videos/"

  @doc """
  Downloads a video from storage to the raw videos directory.
  If a file with the same name already exists, it will be overwritten.

  ## Parameters
    - video_name: The name of the video file (e.g., "video1.mp4")

  ## Returns
    - `{:ok, local_path}` where local_path is the path to the downloaded file
    - `{:error, reason}` if the download fails

  ## Examples
      iex> RawVideoDownloader.download("my_video.mp4")
      {:ok, "priv/static/videos/raw/my_video.mp4"}

      iex> RawVideoDownloader.download("invalid.mp4")
      {:error, "Failed to download video: not_found"}
  """
  @spec download_raw_video(String.t()) :: {:ok, raw_video_local_path()} | {:error, String.t()}
  def download_raw_video(video_name) do
    local_path = local_path_for(video_name)
    storage_key = @raw_videos_prefix <> video_name

    with {:ok, _} <-
           DirectoryAndFileUtils.create_directory_if_not_exists(
             VideoConfig.raw_videos_local_path()
           ),
         {:ok, _} <- Storage.download(VideoConfig.storage_bucket(), storage_key, local_path) do
      {:ok, local_path}
    else
      {:error, reason} ->
        {:error, "Failed to download raw video: #{inspect(reason)}"}
    end
  end

  @spec local_path_for(String.t()) :: String.t()
  def local_path_for(video_name) do
    Path.join(VideoConfig.raw_videos_local_path(), video_name)
  end
end
