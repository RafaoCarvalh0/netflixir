defmodule Netflixir.Videos.StreamPackager do
  @moduledoc """
  Module responsible for packaging videos for streaming.

  This module orchestrates the video packaging pipeline, which includes:
  - Transcoding with intro
  - Creating multiple resolutions
  - HLS packaging (segmentation and playlist creation)

  """
  alias Netflixir.Videos.Processors.HlsProcessor
  alias Netflixir.Videos.Processors.ResolutionProcessor
  alias Netflixir.Videos.Processors.Transcoder

  def process_video(raw_video) do
    with {:ok, transcoded_video} <- Transcoder.transcode_raw_video(raw_video),
         {:ok, resolutions_dir} <-
           ResolutionProcessor.create_video_resolutions(transcoded_video),
         {:ok, video_segments_dir} <- HlsProcessor.create_video_segments(resolutions_dir) do
      {:ok,
       %{
         video_segments_dir: video_segments_dir,
         master_playlist: Path.join(video_segments_dir, "master.m3u8"),
         resolutions_dir: resolutions_dir
       }}
    end
  end
end
