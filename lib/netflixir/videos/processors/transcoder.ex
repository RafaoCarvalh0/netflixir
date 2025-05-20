defmodule Netflixir.Videos.Processors.Transcoder do
  @moduledoc """
  Module responsible for video transcoding using FFmpeg.

  Transcoding is a necessary process for several critical reasons:

  1. Compatibility
     - Not all devices/browsers support all video formats
     - Videos can come from different sources (iPhone, Android, cameras) in different formats
     - H.264 is the most universally supported codec

  2. Optimization
     - Original videos may be in very high quality
     - Original formats may not be optimized for streaming
     - Transcoding allows compression while maintaining acceptable quality

  3. Streaming
     - Adds special flags like 'faststart' for better experience
     - Prepares the video for adaptive streaming techniques
     - Optimizes the format for web transmission

  This module will transcode videos to H.264 (AVC) as it is the codec
  with the highest compatibility across devices and browsers. The output
  format will be MP4 with settings optimized for web streaming.

  """
  alias Netflixir.Utils.DirectoryUtils

  @transcoded_videos_path "priv/static/videos/transcoded"

  # TODO: Remove the example default value for raw_file_path once everything
  # is working.
  @spec transcode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def transcode(raw_file_path \\ "priv/static/videos/raw/cat_rave.mp4") do
    output_file_path = generate_transcoded_file_path(raw_file_path)

    with {:ok, _} <- DirectoryUtils.create_directory_if_not_exists(@transcoded_videos_path),
         {:ok, processed_video_path} <- transcode_with_ffmpeg(raw_file_path, output_file_path) do
      {:ok, processed_video_path}
    else
      {:error, reason} ->
        {:error, "Failed to transcode video: #{reason}"}

      error ->
        {:error, "Failed to transcode video: #{inspect(error)}"}
    end
  end

  defp generate_transcoded_file_path(raw_file_path) do
    output_file_base_name =
      Path.basename(raw_file_path)

    "#{@transcoded_videos_path}/#{output_file_base_name}"
  end

  defp transcode_with_ffmpeg(raw_file_path, output_path) do
    args = build_ffmpeg_transcoding_args(raw_file_path, output_path)

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_, 0} -> {:ok, output_path}
      {error, _} -> {:error, error}
    end
  end

  defp build_ffmpeg_transcoding_args(raw_file_path, output_path) do
    h264_codec_ffmpeg_lib = "libx264"

    input_file = ["-i", raw_file_path]
    video_codec = ["-c:v", h264_codec_ffmpeg_lib]

    # AAC has better quality, compatibility, compression and efficiency than MP3
    audio_codec = ["-c:a", "aac"]

    # 2 Megabits per second is a good compromise between quality and size
    video_bitrate = ["-b:v", "2M"]

    # 128 kilobits per second is a good compromise between quality and size
    audio_bitrate = ["-b:a", "128k"]

    # The -preset defines the balance between compression velocity and quality
    # Slow preset takes longer to transcode but produces a better quality video
    preset = ["-preset", "slow"]

    List.flatten([
      input_file,
      video_codec,
      audio_codec,
      video_bitrate,
      audio_bitrate,
      preset,
      output_path
    ])
  end
end
