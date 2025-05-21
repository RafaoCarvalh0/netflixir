defmodule Netflixir.Videos.Externals.VideoExternal do
  @moduledoc """
  External representation of a video.
  Contains all the necessary fields for frontend display and interaction.
  """

  @processed_videos_prefix "processed_videos/"

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          created_at: String.t() | nil,
          status: String.t(),
          playlist_path: String.t(),
          thumbnail: String.t()
        }

  defstruct [
    :id,
    :title,
    :created_at,
    :playlist_path,
    :thumbnail,
    :status
  ]

  @spec from_storage(String.t(), String.t() | nil, String.t(), String.t()) :: t()
  def from_storage(storage_path, created_at, thumbnail_url, playlist_path) do
    video_id = extract_video_name(storage_path)

    %__MODULE__{
      id: video_id,
      title: format_title(video_id),
      created_at: created_at,
      status: "Ready",
      playlist_path: playlist_path,
      thumbnail: thumbnail_url
    }
  end

  defp extract_video_name(storage_path) do
    if String.contains?(storage_path, @processed_videos_prefix) do
      storage_path
      |> String.replace(@processed_videos_prefix, "")
      |> String.split("/")
      |> List.first()
    else
      storage_path
    end
  end

  defp format_title(filename) do
    filename
    |> String.replace(~r/[_-]/, " ")
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
