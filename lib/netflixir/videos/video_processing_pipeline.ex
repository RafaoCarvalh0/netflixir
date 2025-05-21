defmodule Netflixir.Videos.VideoProcessingPipeline do
  @moduledoc """
  Pipeline responsible for processing videos through multiple stages to prepare them for streaming.

  This pipeline orchestrates the complete video processing workflow through sequential stages:

  1. Transcoding Stage:
     - Converts video to H.264/MP4
     - Adds intro video
     - Ensures format compatibility

  2. Resolution Stage:
     - Creates multiple resolution variants
     - Optimizes for different devices/connections
     - Uploads variants to storage

  3. HLS Stage:
     - Segments videos for streaming
     - Creates resolution-specific playlists
     - Creates master playlist
     - Uploads all HLS content

  Each stage is handled by a specialized processor module, and this pipeline
  ensures they are executed in the correct order with proper error handling.
  """
  alias Netflixir.Videos.Processors.HlsProcessor
  alias Netflixir.Videos.Processors.ResolutionProcessor
  alias Netflixir.Videos.Processors.Transcoder

  @type process_result :: %{
          hls_storage_path: String.t()
        }

  @spec process_video(String.t()) :: {:ok, process_result()} | {:error, String.t()}
  def process_video(raw_video_full_path) do
    with {:ok, transcoded_video} <- Transcoder.transcode_and_add_intro(raw_video_full_path),
         {:ok, video_resolutions_local_dir} <-
           ResolutionProcessor.create_video_resolutions(transcoded_video),
         {:ok, hls_storage_path} <-
           HlsProcessor.create_video_segments(video_resolutions_local_dir) do
      {:ok,
       %{
         hls_storage_path: hls_storage_path
       }}
    end
  end
end
