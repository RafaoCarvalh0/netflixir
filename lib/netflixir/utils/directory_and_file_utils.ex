defmodule Netflixir.Utils.DirectoryAndFileUtils do
  @moduledoc """
  Utility functions for handling directory and file operations.

  This module provides functions for:
  - Creating directories
  - Getting directory information
  - Removing files
  - Removing directories and their contents
  """

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

  @spec remove_file_if_exists(String.t()) ::
          {:ok, String.t() | :does_not_exist} | {:error, String.t()}
  def remove_file_if_exists(file_path) do
    if File.exists?(file_path) do
      case File.rm(file_path) do
        :ok -> {:ok, file_path}
        {:error, reason} -> {:error, "Failed to remove #{file_path}: #{inspect(reason)}"}
      end
    else
      {:ok, :does_not_exist}
    end
  end

  @spec remove_dir_if_exists(String.t()) ::
          {:ok, String.t() | :does_not_exist} | {:error, String.t()}
  def remove_dir_if_exists(dir_path) do
    if File.exists?(dir_path) do
      case File.rm_rf(dir_path) do
        {:ok, _} ->
          {:ok, dir_path}

        {:error, reason, _} ->
          {:error, "Failed to remove directory #{dir_path}: #{inspect(reason)}"}
      end
    else
      {:ok, :does_not_exist}
    end
  end
end
