defmodule Netflixir.Videos.Processors.HLSProcessor do
  @moduledoc """
  Module responsible for creating HLS (HTTP Live Streaming) segments from videos.

  HLS is a streaming protocol developed by Apple that has become an industry standard.
  It works by:
  1. Dividing videos into small segments (chunks)
  2. Creating multiple quality versions of the same video
  3. Using playlists (.m3u8) to organize segments
  4. Allowing players to dynamically switch quality

  This module takes videos in different resolutions and:
  - Segments each resolution into small chunks (6 seconds each)
  - Creates a playlist (playlist.m3u8) for each resolution
  - Creates a master playlist (master.m3u8) that lists all available qualities

  Why HLS segmentation is necessary:
  - Enables adaptive bitrate streaming
  - Allows faster video startup (no need to download entire file)
  - Makes it possible to switch quality without interruption
  - Improves caching and delivery efficiency
  - Used by major streaming services (Netflix, YouTube, etc.)

  """
  alias Netflixir.Utils.DirectoryUtils
  alias Netflixir.Utils.FfmpegUtils
  alias Netflixir.Videos.Processors.ResolutionProcessor

  @hls_path "priv/static/videos/hls"

  # TODO: Remove the example default value for resolutions_dir once everything
  # is working.
  @spec process_hls(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def process_hls(resolutions_dir \\ "priv/static/videos/resolutions/cat_rave") do
    hls_output_dir = @hls_path <> "/" <> Path.basename(resolutions_dir)

    with {:ok, _} <- DirectoryUtils.create_directory_if_not_exists(hls_output_dir),
         {:ok, _} <- create_hls_segments(resolutions_dir, hls_output_dir),
         :ok <- create_master_playlist(hls_output_dir) do
      {:ok, hls_output_dir}
    else
      {:error, reason} -> {:error, "Failed to create HLS: #{reason}"}
    end
  end

  defp create_hls_segments(resolutions_dir, hls_output_dir) do
    response =
      resolutions_dir
      |> File.ls!()
      |> Task.async_stream(
        &create_segments_for_resolution(resolutions_dir, hls_output_dir, &1),
        timeout: :infinity
      )
      |> Enum.into([])

    case Enum.all?(response, &match?({:ok, _}, &1)) do
      true -> {:ok, response}
      false -> {:error, "Failed to create segments for one or more resolutions"}
    end
  end

  defp create_segments_for_resolution(resolutions_dir, hls_output_dir, video_file) do
    resolution_name = Path.basename(video_file, ".mp4")
    resolution_hls_dir = "#{hls_output_dir}/#{resolution_name}"
    input_path = "#{resolutions_dir}/#{video_file}"

    hls_args = build_ffmpeg_hls_args(input_path, resolution_hls_dir)

    with {:ok, _} <- DirectoryUtils.create_directory_if_not_exists(resolution_hls_dir),
         {:ok, :success} <- FfmpegUtils.run_ffmpeg(hls_args) do
      {:ok, resolution_hls_dir}
    else
      error -> {:error, "Failed to create HLS for #{resolution_name}: #{inspect(error)}"}
    end
  end

  defp build_ffmpeg_hls_args(input_path, output_dir) do
    force_overwrite = "-y"

    input_file = ["-i", input_path]

    # Use copy codec since files should be already in the right format at this point
    stream_copy = ["-c", "copy"]

    format = ["-f", "hls"]

    # 6 second segments
    segment_time = ["-hls_time", "6"]

    # Keep all segments
    segment_list_size = ["-hls_list_size", "0"]

    # Segment naming pattern
    segment_filename = [
      "-hls_segment_filename",
      "#{output_dir}/segment_%03d.ts"
    ]

    output_playlist = ["#{output_dir}/playlist.m3u8"]

    List.flatten([
      force_overwrite,
      input_file,
      stream_copy,
      format,
      segment_time,
      segment_list_size,
      segment_filename,
      output_playlist
    ])
  end

  defp create_master_playlist(hls_output_dir) do
    resolutions = ResolutionProcessor.get_available_video_resolutions()

    # This is the HLS master playlist format:
    #
    # #EXTM3U              - Indicates this is an M3U playlist file
    # #EXT-X-VERSION:3     - Specifies HLS protocol version 3
    #
    # The master playlist lists all available video qualities.
    # Each quality entry includes:
    # - BANDWIDTH: The bitrate in bits per second
    # - RESOLUTION: The video dimensions
    # Example:
    # #EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
    # 720p/playlist.m3u8
    #
    # This allows video players to:
    # 1. See all available qualities
    # 2. Choose initial quality based on network speed
    # 3. Switch between qualities during playback
    # 4. Find the location of each quality's playlist
    content = """
    #EXTM3U
    #EXT-X-VERSION:3
    #{build_master_playlist_entries(resolutions)}
    """

    File.write("#{hls_output_dir}/master.m3u8", content)
  end

  # This function builds the entries for each quality in the master playlist:
  #
  # Enum.map_join - Maps over each resolution and joins with newlines
  # For each resolution it creates two lines:
  #
  # 1. #EXT-X-STREAM-INF - Stream information tag that specifies:
  #    - BANDWIDTH: The bitrate (e.g. 2800000 for 2.8Mbps)
  #    - RESOLUTION: Video dimensions (e.g. 1280x720)
  #
  # 2. Path to that quality's playlist (e.g. 720p/playlist.m3u8)
  defp build_master_playlist_entries(resolutions) do
    Enum.map_join(resolutions, "\n", fn resolution ->
      """
      #EXT-X-STREAM-INF:BANDWIDTH=#{resolution.bandwidth},RESOLUTION=#{resolution.resolution}
      #{resolution.name}/playlist.m3u8
      """
    end)
  end
end
