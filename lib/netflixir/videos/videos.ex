# lib/netflixir/videos.ex
defmodule Netflixir.Videos do
  @moduledoc """
  The Videos context.
  Handles all video-related operations including listing, processing and streaming.
  """
  alias Netflixir.Utils.DirectoryUtils

  @default_hls_dir "priv/static/videos/hls"
  @default_master_playlist_name "master.m3u8"

  def list_available_videos do
    Path.wildcard("#{@default_hls_dir}/*")
    |> Enum.map(fn dir ->
      video_name = Path.basename(dir)
      master_playlist = Path.join([dir, @default_master_playlist_name])

      if File.exists?(master_playlist) do
        %{
          id: video_name,
          title: format_title(video_name),
          created_at: DirectoryUtils.get_directory_creation_date(dir),
          status: "Ready",
          playlist_path: "/videos/hls/#{video_name}/#{@default_master_playlist_name}"
        }
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp format_title(filename) do
    filename
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def get_video_by_id!(video_id) do
    video_dir = Path.join(["priv/static/videos/hls", video_id])
    master_playlist = Path.join([video_dir, "master.m3u8"])

    if File.exists?(master_playlist) do
      %{
        id: video_id,
        title: format_title(video_id),
        playlist_path: "/videos/hls/#{video_id}/master.m3u8"
      }
    else
      raise "Video not found"
    end
  end
end
