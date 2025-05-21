defmodule Netflixir.Videos.Processors.ResolutionProcessor do
  @moduledoc """
  Module responsible for creating multiple resolution versions of a video.

  This module takes a transcoded H.264/MP4 video and creates different quality versions
  optimized for adaptive streaming. Each version is tailored for different network
  conditions and device capabilities.

  Available Resolutions:
  - 1080p (1920x1080) - High quality, 5Mbps
  - 720p (1280x720) - Medium quality, 2.8Mbps
  - 480p (854x480) - Low quality, 1.4Mbps
  - 360p (640x360) - Mobile quality, 800Kbps

  Why multiple resolutions are necessary:
  - Different devices have different screen sizes
  - Network conditions vary (mobile, wifi, fiber)
  - Users may prefer to save bandwidth
  - Required for adaptive bitrate streaming

  Each resolution version is created with:
  - Specific video bitrate for quality/size balance
  - Matching audio bitrate
  - H.264 codec for maximum compatibility
  - Faststart flag for quick playback
  - Optimized for streaming

  This is the second step in the video processing pipeline:
  1. Transcoding (H.264 conversion)
  2. Multiple Resolutions (this module)
  3. HLS Segmentation

  Used by streaming services to ensure optimal playback across all devices
  and network conditions.
  """
  alias Netflixir.Storage
  alias Netflixir.Utils.DirectoryUtils
  alias Netflixir.Utils.FfmpegUtils
  alias Netflixir.Videos.VideoConfig

  @type resolution_path :: String.t()
  @type resolution_storage_path :: String.t()

  @spec create_video_resolutions(String.t()) ::
          {:ok, [resolution_storage_path()]}
          | {:error, String.t()}
  def create_video_resolutions(transcoded_video_path) do
    video_name = Path.basename(transcoded_video_path, ".mp4")
    resolutions_dir = resolutions_local_path_for(video_name)

    with {:ok, _} <- DirectoryUtils.create_directory_if_not_exists(resolutions_dir),
         {:ok, local_paths} <- create_resolutions(transcoded_video_path, resolutions_dir),
         {:ok, storage_paths} <- upload_resolutions(video_name, local_paths) do
      {:ok, storage_paths}
    else
      {:error, reason} -> {:error, "Failed to create video resolutions: #{reason}"}
    end
  end

  defp create_resolutions(transcoded_video_path, resolutions_dir) do
    available_resolutions = VideoConfig.video_resolutions()

    response =
      available_resolutions
      |> Task.async_stream(
        &create_resolution(transcoded_video_path, resolutions_dir, &1),
        timeout: :infinity
      )
      |> Enum.into([])

    case Enum.split_with(response, &match?({:ok, _}, &1)) do
      {successes, []} ->
        {:ok, Enum.map(successes, fn {:ok, path} -> path end)}

      {_, failures} ->
        {:error, "Failed to create some resolutions: #{inspect(failures)}"}
    end
  end

  defp create_resolution(transcoded_video_path, resolutions_dir, resolution) do
    output_path = Path.join(resolutions_dir, "#{resolution.name}.mp4")
    args = build_ffmpeg_resolution_args(transcoded_video_path, resolution, output_path)

    case FfmpegUtils.run_ffmpeg(args) do
      {:ok, :success} -> output_path
      error -> error
    end
  end

  defp upload_resolutions(video_name, local_paths) do
    response =
      local_paths
      |> Task.async_stream(
        &upload_resolution(video_name, &1),
        timeout: :infinity
      )
      |> Enum.into([])

    case Enum.split_with(response, &match?({:ok, _}, &1)) do
      {successes, []} -> {:ok, Enum.map(successes, fn {:ok, path} -> path end)}
      {_, failures} -> {:error, "Failed to upload some resolutions: #{inspect(failures)}"}
    end
  end

  defp upload_resolution(video_name, local_path) when is_binary(local_path) do
    resolution_name = Path.basename(local_path)
    storage_key = "processed_videos/#{video_name}/resolutions/#{resolution_name}"

    case Storage.upload(local_path, VideoConfig.storage_bucket(), storage_key) do
      {:ok, storage_path} -> {:ok, storage_path}
      error -> error
    end
  end

  defp build_ffmpeg_resolution_args(
         transcoded_video_path,
         resolution,
         output_path
       ) do
    force_overwrite = "-y"

    input_file = ["-i", transcoded_video_path]

    # Video scaling filter for different resolutions
    video_filter = ["-vf", "scale=#{resolution.resolution}"]

    # Use H.264 codec for maximum compatibility
    video_codec = ["-c:v", "libx264"]

    # Video bitrate varies according to resolution
    # Higher resolution = higher bitrate for quality
    video_bitrate = ["-b:v", resolution.bitrate]

    # AAC has better quality, compatibility, compression and efficiency than MP3
    audio_codec = ["-c:a", "aac"]

    # Audio bitrate varies according to resolution
    # Higher quality video = higher quality audio
    audio_bitrate = ["-b:a", resolution.audio_bitrate]

    # The -preset defines the balance between compression velocity and quality
    # A slow preset takes longer to process but produces a video with better overall quality
    preset = ["-preset", "slow"]

    # The faststart enables the video to be played in the browser
    # without waiting for the entire file to download
    # Crucial for streaming
    movflags = ["-movflags", "+faststart"]

    List.flatten([
      force_overwrite,
      input_file,
      video_filter,
      video_codec,
      video_bitrate,
      audio_codec,
      audio_bitrate,
      preset,
      movflags,
      output_path
    ])
  end

  defp resolutions_local_path_for(video_name) do
    Path.join(VideoConfig.resolutions_local_path(), video_name)
  end
end
