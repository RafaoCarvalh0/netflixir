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

  @spec transcode_raw_video(String.t()) :: {:ok, transcoded_video()} | {:error, String.t()}
  def transcode_raw_video(raw_video) do
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

    input_files = [
      "-i",
      intro_file,
      "-i",
      raw_video
    ]

    # Filter Complex: Video/audio processing pipeline
    # [0:v] - First input (intro) video stream
    # [1:v] - Second input (main video) video stream
    # [0:a] - First input audio stream
    # [1:a] - Second input audio stream
    #
    # For intro video:
    # 1. Scale to match the main video's dimensions using [1:v]'s width and height
    # 2. force_original_aspect_ratio=decrease - Maintain original aspect ratio
    # 3. pad to match main video's dimensions, centered
    #
    # For main video:
    # Keep original dimensions, no scaling needed
    #
    # Concatenation:
    # [v0][0:a][v1][1:a] - Takes streams in order: video1, audio1, video2, audio2
    # concat=n=2:v=1:a=1 - Concatenates 2 inputs, generating 1 video and 1 audio
    # [outv][outa] - Names output streams as 'outv' and 'outa'
    filter_complex = [
      "-filter_complex",
      "[1:v][0:v]scale2ref[v1][v0];
       [v0]pad=iw:ih:(ow-iw)/2:(oh-ih)/2[padded_intro];
       [padded_intro][0:a][v1][1:a]concat=n=2:v=1:a=1[outv][outa]"
    ]

    # Output Mapping: Defines which streams to use in the final file
    # -map "[outv]" - Uses the processed video stream (after scale and concat)
    # -map "[outa]" - Uses the processed audio stream (after concat)
    #
    # This is necessary because:
    # 1. We have multiple input streams (2 videos, 2 audios)
    # 2. We process them in the filter_complex
    # 3. We need to tell FFmpeg exactly which streams to use in the output
    output_map = [
      "-map",
      "[outv]",
      "-map",
      "[outa]"
    ]

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
