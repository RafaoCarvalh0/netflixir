defmodule Netflixir.Videos.Externals.VideoExternal do
  @moduledoc """
  External representation of a video.
  Contains all the necessary fields for frontend display and interaction.
  """

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

  @spec from_storage(String.t(), String.t(), String.t(), String.t()) :: t()
  def from_storage(video_id, created_at, playlist_path, thumbnail) do
    %__MODULE__{
      id: video_id,
      title: format_title(video_id),
      created_at: created_at,
      status: "Ready",
      playlist_path: playlist_path,
      thumbnail: thumbnail
    }
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
