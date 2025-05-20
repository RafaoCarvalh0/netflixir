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
  alias Netflixir.Utils.DirectoryUtils
  alias Netflixir.Utils.FfmpegUtils

  @resolutions_path "priv/static/videos/resolutions"

  # TODO: Remove the example default value for transcoded_video_path once everything
  # is working.
  def process_resolutions(transcoded_video_path \\ "priv/static/videos/transcoded/cat_rave.mp4") do
    transcoded_video_resolutions_dir =
      @resolutions_path <> "/" <> Path.basename(transcoded_video_path, ".mp4")

    with {:ok, _} <-
           DirectoryUtils.create_directory_if_not_exists(transcoded_video_resolutions_dir),
         {:ok, _} <-
           create_resolutions(transcoded_video_path, transcoded_video_resolutions_dir) do
      {:ok, transcoded_video_resolutions_dir}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_resolutions(transcoded_video_path, transcoded_video_resolutions_dir) do
    response =
      get_available_video_resolutions()
      |> Task.async_stream(
        &create_resolution(transcoded_video_path, transcoded_video_resolutions_dir, &1),
        timeout: :infinity
      )
      |> Enum.into([])

    cond do
      Enum.all?(response, &match?({:ok, _}, &1)) -> {:ok, response}
      Enum.any?(response, &match?({:error, _}, &1)) -> {:error, inspect(response)}
      true -> {:error, "Unknown error"}
    end
  end

  defp create_resolution(transcoded_video_path, transcoded_video_resolutions_dir, resolution) do
    output_path = "#{transcoded_video_resolutions_dir}/#{resolution.name}.mp4"
    args = build_ffmpeg_resolution_args(transcoded_video_path, resolution, output_path)

    case FfmpegUtils.run_ffmpeg(args) do
      {:ok, :success} -> {:ok, output_path}
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
    # Slow preset takes longer to process but produces a better quality video
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

  @spec get_available_video_resolutions :: [
          %{
            name: String.t(),
            resolution: String.t(),
            bitrate: String.t(),
            audio_bitrate: String.t(),
            bandwidth: String.t()
          }
        ]
  def get_available_video_resolutions do
    Application.get_env(:netflixir, :video_resolutions)
  end
end
