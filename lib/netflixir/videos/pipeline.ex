defmodule Netflixir.Videos.Pipeline do
  @moduledoc """
  Module responsible for processing videos through a series of steps.

  This module orchestrates the video processing pipeline, which includes:

  - Transcoding
  - Creating multiple resolutions
  - Creating HLS playlists
  """
  alias Netflixir.Videos.Processors.HlsProcessor
  alias Netflixir.Videos.Processors.ResolutionProcessor
  alias Netflixir.Videos.Processors.Transcoder

  def process_video(raw_video \\ "priv/static/videos/raw/cat_rave.mp4") do
    with {:ok, transcoded_video} <- Transcoder.transcode_raw_video(raw_video),
         {:ok, resolution_paths} <-
           ResolutionProcessor.create_video_resolutions(transcoded_video),
         {:ok, video_segments_dir} <- HlsProcessor.create_video_segments(resolution_paths) do
      File.rm(transcoded_video)

      {:ok,
       %{
         video_segments_dir: video_segments_dir,
         master_playlist: Path.join(video_segments_dir, "master.m3u8"),
         resolutions: resolution_paths
       }}
    end
  end
end
