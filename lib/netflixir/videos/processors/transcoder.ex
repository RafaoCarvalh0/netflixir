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

  It also adds the intro to the video.
  """
  alias Netflixir.Utils.DirectoryUtils
  alias Netflixir.Utils.FfmpegUtils
  alias Netflixir.Videos.VideoConfig

  @type transcoded_video :: String.t()

  @doc """
  Transcodes a raw video to H.264/MP4 format and adds an intro to it.

  The function will:
  1. Create the transcoded videos directory if it doesn't exist
  2. Convert the video to H.264 codec with MP4 container
  3. Add the configured intro video at the beginning
  4. Maintain original video quality while scaling intro to match


  ## Examples
      iex> Transcoder.transcode_and_add_intro("priv/static/videos/raw/video1.mp4")
      {:ok, "priv/static/videos/transcoded/video1.mp4"}

      iex> Transcoder.transcode_and_add_intro("invalid.mp4")
      {:error, "Failed to transcode video: file not found"}
  """
  @spec transcode_and_add_intro(String.t()) :: {:ok, transcoded_video()} | {:error, String.t()}
  def transcode_and_add_intro(raw_video) do
    output_file_path = transcoded_file_path(raw_video)
    transcoded_videos_path = VideoConfig.transcoded_videos_local_path()

    with {:ok, _} <- DirectoryUtils.create_directory_if_not_exists(transcoded_videos_path),
         {:ok, transcoded_video} <- transcode_with_intro(raw_video, output_file_path) do
      {:ok, transcoded_video}
    else
      {:error, reason} ->
        {:error, "Failed to transcode video: #{reason}"}

      error ->
        {:error, "Failed to transcode video: #{inspect(error)}"}
    end
  end

  defp transcoded_file_path(raw_video) do
    output_file_base_name = Path.basename(raw_video)
    Path.join(VideoConfig.transcoded_videos_local_path(), output_file_base_name)
  end

  defp transcode_with_intro(raw_video, output_path) do
    raw_video
    |> build_ffmpeg_transcoding_args(output_path)
    |> FfmpegUtils.run_ffmpeg()
    |> case do
      {:ok, :success} -> {:ok, output_path}
      error -> error
    end
  end

  defp build_ffmpeg_transcoding_args(raw_video, output_path) do
    force_overwrite = "-y"
    h264_codec_ffmpeg_lib = "libx264"
    intro_file = VideoConfig.intro_video_local_path()

    # Input files order matters:
    # First input (0): raw video
    # Second input (1): intro
    input_files = [
      "-i",
      raw_video,
      "-i",
      intro_file
    ]

    # Filter Complex: Video/audio processing pipeline
    # [0:v] - First input (raw video) video stream
    # [1:v] - Second input (intro) video stream
    # [0:a] - First input audio stream
    # [1:a] - Second input audio stream
    #
    # 1. Scale both videos to 1920x1080
    # 2. Pad if needed to maintain aspect ratio
    # 3. Concatenate intro followed by the main video
    filter_complex = [
      "-filter_complex",
      "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2[v0];
       [1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2[v1];
       [v1][1:a][v0][0:a]concat=n=2:v=1:a=1[outv][outa]"
    ]

    # Output Mapping: Defines which streams to use in the final file
    # -map "[outv]" - Uses the processed video stream (after scale and concat)
    # -map "[outa]" - Uses the processed audio stream (after concat)
    output_map = [
      "-map",
      "[outv]",
      "-map",
      "[outa]"
    ]

    # Use H.264 codec for maximum compatibility across devices and browsers
    video_codec = ["-c:v", h264_codec_ffmpeg_lib]

    # 2 Megabits per second is a good compromise between quality and size
    video_bitrate = ["-b:v", "2M"]

    # AAC has better quality, compatibility, compression and efficiency than MP3
    audio_codec = ["-c:a", "aac"]

    # 128 kilobits per second is a good compromise between quality and size
    audio_bitrate = ["-b:a", "128k"]

    # The -preset defines the balance between compression velocity and quality
    # Slow preset provides better compression (smaller file size) at the cost of increased encoding time
    preset = ["-preset", "slow"]

    List.flatten([
      force_overwrite,
      input_files,
      filter_complex,
      output_map,
      video_codec,
      video_bitrate,
      audio_codec,
      audio_bitrate,
      preset,
      output_path
    ])
  end
end
