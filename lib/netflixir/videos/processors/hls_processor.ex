defmodule Netflixir.Videos.Processors.HlsProcessor do
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
  - Uploads all segments and playlists to storage for streaming

  Why HLS segmentation is necessary:
  - Enables adaptive bitrate streaming
  - Allows faster video startup (no need to download entire file)
  - Makes it possible to switch quality without interruption
  - Improves caching and delivery efficiency
  - Used by major streaming services (Netflix, YouTube, etc.)

  """
  alias Netflixir.Storage
  alias Netflixir.Utils.DirectoryUtils
  alias Netflixir.Utils.FfmpegUtils
  alias Netflixir.Videos.VideoConfig

  @type video_segments_dir :: String.t()
  @type segments_storage_path :: String.t()

  @master_playlist_filename "master.m3u8"
  @resolution_playlist_filename "playlist.m3u8"
  @segment_file_extension ".ts"

  @spec create_video_segments(String.t()) :: {:ok, segments_storage_path()} | {:error, String.t()}
  def create_video_segments(resolutions_local_dir) do
    video_name = Path.basename(resolutions_local_dir)
    video_segments_local_dir = Path.join(VideoConfig.hls_local_path(), video_name)

    with {:ok, _} <- DirectoryUtils.create_directory_if_not_exists(video_segments_local_dir),
         {:ok, _} <- create_hls_segments(resolutions_local_dir, video_segments_local_dir),
         :ok <- create_master_playlist(video_segments_local_dir),
         {:ok, storage_path} <- upload_segments(video_name, video_segments_local_dir) do
      {:ok, storage_path}
    else
      {:error, reason} -> {:error, "Failed to create HLS: #{reason}"}
    end
  end

  defp upload_segments(video_name, video_segments_local_dir) do
    storage_base_path = "processed_videos/#{video_name}/hls"

    with {:ok, _} <- upload_master_playlist(video_segments_local_dir, storage_base_path),
         {:ok, _} <- upload_resolution_segments(video_segments_local_dir, storage_base_path) do
      {:ok, storage_base_path}
    end
  end

  defp upload_master_playlist(video_segments_local_dir, storage_base_path) do
    local_path = Path.join(video_segments_local_dir, @master_playlist_filename)
    storage_key = "#{storage_base_path}/#{@master_playlist_filename}"

    Storage.upload(local_path, VideoConfig.storage_bucket(), storage_key)
  end

  defp upload_resolution_segments(video_segments_local_dir, storage_base_path) do
    available_resolutions = VideoConfig.video_resolutions()

    response =
      available_resolutions
      |> Map.keys()
      |> Task.async_stream(
        &upload_resolution_files(video_segments_local_dir, storage_base_path, &1),
        timeout: :infinity
      )
      |> Enum.into([])

    case Enum.split_with(response, &match?({:ok, _}, &1)) do
      {_successes, []} -> {:ok, storage_base_path}
      {_, failures} -> {:error, "Failed to upload some resolution segments: #{inspect(failures)}"}
    end
  end

  defp upload_resolution_files(video_segments_local_dir, storage_base_path, resolution_name) do
    resolution_dir = Path.join(video_segments_local_dir, resolution_name)
    resolution_storage_path = "#{storage_base_path}/#{resolution_name}"

    with {:ok, files} <- File.ls(resolution_dir),
         :ok <- upload_resolution_playlist(resolution_dir, resolution_storage_path),
         :ok <- upload_resolution_segments(resolution_dir, resolution_storage_path, files) do
      {:ok, resolution_storage_path}
    end
  end

  defp upload_resolution_playlist(resolution_dir, resolution_storage_path) do
    local_path = Path.join(resolution_dir, @resolution_playlist_filename)
    storage_key = "#{resolution_storage_path}/#{@resolution_playlist_filename}"

    case Storage.upload(local_path, VideoConfig.storage_bucket(), storage_key) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp upload_resolution_segments(resolution_dir, resolution_storage_path, files) do
    segment_files = Enum.filter(files, &String.ends_with?(&1, @segment_file_extension))

    results =
      segment_files
      |> Task.async_stream(
        fn segment_file ->
          local_path = Path.join(resolution_dir, segment_file)
          storage_key = "#{resolution_storage_path}/#{segment_file}"

          Storage.upload(local_path, VideoConfig.storage_bucket(), storage_key)
        end,
        timeout: :infinity
      )
      |> Enum.into([])

    case Enum.split_with(results, &match?({:ok, _}, &1)) do
      {_successes, []} -> :ok
      {_, failures} -> {:error, "Failed to upload segments: #{inspect(failures)}"}
    end
  end

  defp create_hls_segments(resolutions_local_dir, video_segments_local_dir) do
    response =
      resolutions_local_dir
      |> File.ls!()
      |> Task.async_stream(
        &create_segments_for_resolution(resolutions_local_dir, video_segments_local_dir, &1),
        timeout: :infinity
      )
      |> Enum.into([])

    if Enum.all?(response, &match?({:ok, _}, &1)) do
      {:ok, response}
    else
      {:error, response}
    end
  end

  defp create_segments_for_resolution(resolutions_local_dir, video_segments_local_dir, video_file) do
    resolution_name = Path.basename(video_file, ".mp4")
    resolution_hls_dir = "#{video_segments_local_dir}/#{resolution_name}"
    input_path = "#{resolutions_local_dir}/#{video_file}"

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

    output_playlist = ["#{output_dir}/#{@resolution_playlist_filename}"]

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

  defp create_master_playlist(video_segments_local_dir) do
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
    #{build_master_playlist_entries()}
    """

    File.write("#{video_segments_local_dir}/#{@master_playlist_filename}", content)
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
  defp build_master_playlist_entries() do
    available_resolutions = VideoConfig.video_resolutions()

    available_resolutions
    |> Map.keys()
    |> Enum.sort(:desc)
    |> Enum.map_join("\n", fn resolution_name ->
      resolution = available_resolutions[resolution_name]

      """
      #EXT-X-STREAM-INF:BANDWIDTH=#{resolution.bandwidth},RESOLUTION=#{resolution.resolution}
      #{resolution.name}/#{@resolution_playlist_filename}
      """
    end)
  end
end
