defmodule Netflixir.Videos.VideoConfig do
  @moduledoc """
  Module responsible for managing video-related configurations.
  Provides a clean interface to access video configurations while encapsulating
  the actual configuration structure and implementation details.
  """

  @doc """
  Gets the path where raw videos are stored locally.
  """
  @spec raw_videos_path :: String.t()
  def raw_videos_path, do: get_path_config(:raw_videos_local_path)

  @doc """
  Gets the path where transcoded videos are stored.
  """
  @spec transcoded_videos_path :: String.t()
  def transcoded_videos_path, do: get_path_config(:transcoded_videos_path)

  @doc """
  Gets the path to the intro video file.
  """
  @spec intro_file_path :: String.t()
  def intro_file_path, do: get_path_config(:intro_file_path)

  @doc """
  Gets the list of all configured video resolutions.
  Returns them in order from highest to lowest quality (based on resolution).
  """
  @spec video_resolutions :: [map()]
  def video_resolutions do
    resolutions = get_video_config(:resolutions)

    keys =
      resolutions
      |> Map.keys()
      |> Enum.sort(:desc)

    Enum.map(keys, &resolutions[&1])
  end

  @doc """
  Gets a specific resolution configuration by name.

  ## Parameters
    - name: The resolution name (e.g., "1080p", "720p")

  ## Returns
    - The resolution configuration map if found
    - nil if not found

  ## Examples
      iex> VideoConfig.get_resolution("1080p")
      %{name: "1080p", resolution: "1920x1080", ...}

      iex> VideoConfig.get_resolution("invalid")
      nil
  """
  @spec get_resolution(String.t()) :: map() | nil
  def get_resolution(name) do
    get_video_config(:resolutions)[name]
  end

  defp get_path_config(key) do
    get_video_config(:paths)[key]
  end

  defp get_video_config(key) do
    Application.fetch_env!(:netflixir, :videos)[key]
  end
end
