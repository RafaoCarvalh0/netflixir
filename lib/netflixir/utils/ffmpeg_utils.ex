defmodule Netflixir.Utils.FfmpegUtils do
  @moduledoc """
  A simple wrapper for running ffmpeg commands.
  """

  @spec run_ffmpeg([String.t()]) :: {:ok, :success} | {:error, String.t()}
  def run_ffmpeg(args) do
    "ffmpeg"
    |> System.cmd(args, stderr_to_stdout: true)
    |> case do
      {_, 0} -> {:ok, :success}
      {error, _} -> {:error, inspect(error)}
    end
  end
end
