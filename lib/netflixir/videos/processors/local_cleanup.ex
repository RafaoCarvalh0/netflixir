defmodule Netflixir.Videos.Processors.LocalCleanup do
  @moduledoc """
  Module responsible for cleaning up local files after processing.

  After a video is processed and uploaded to storage, this module removes all
  temporary local files created during the processing pipeline, including:
  - Transcoded video file
  - Resolution variants
  - HLS segments and playlists
  """
  alias Netflixir.Utils.DirectoryAndFileUtils
  alias Netflixir.Videos.VideoConfig

  @spec delete_video_local_files(String.t()) :: {:ok, list(String.t())} | {:error, String.t()}
  def delete_video_local_files(video_name) do
    transcoded_video = Path.join(VideoConfig.transcoded_videos_local_path(), "#{video_name}.mp4")
    resolutions_dir = Path.join(VideoConfig.resolutions_local_path(), video_name)
    hls_dir = Path.join(VideoConfig.hls_local_path(), video_name)

    with {:ok, transcoded} <- DirectoryAndFileUtils.remove_file_if_exists(transcoded_video),
         {:ok, resolutions} <- DirectoryAndFileUtils.remove_dir_if_exists(resolutions_dir),
         {:ok, hls} <- DirectoryAndFileUtils.remove_dir_if_exists(hls_dir) do
      {:ok, [transcoded, resolutions, hls]}
    else
      {:error, reason} ->
        {:error, "Failed to clean up local files for video #{video_name}: #{reason}"}
    end
  end
end
