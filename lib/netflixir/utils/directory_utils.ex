defmodule Netflixir.Utils.DirectoryUtils do
  @spec create_directory_if_not_exists(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def create_directory_if_not_exists(path) do
    if File.exists?(path) do
      {:ok, path}
    else
      create_directory(path)
    end
  end

  defp create_directory(path) do
    case File.mkdir_p(path) do
      :ok -> {:ok, path}
      {:error, reason} -> {:error, format_reason(reason)}
    end
  end

  defp format_reason(:eacces),
    do: "directory missing search or write permissions for the parent directories of path"

  defp format_reason(:enospc), do: "there is no space left on the device"
  defp format_reason(:enotdir), do: "a component of path is not a directory"

  def get_directory_creation_date(dir) do
    case File.stat(dir) do
      {:ok, %{ctime: creation_time}} ->
        creation_time
        |> NaiveDateTime.from_erl!()
        |> Calendar.strftime("%Y-%m-%d %H:%M:%S")

      _ ->
        "Unknown"
    end
  end
end
