defmodule Netflixir.Storage.Local do
  @moduledoc """
  Local filesystem implementation of the Storage behaviour.
  Files are stored directly in the local filesystem.
  """
  @behaviour Netflixir.Storage

  @impl true
  def list_directories(prefix) do
    path = Path.join(Netflixir.Storage.storage_bucket(), prefix)

    if File.exists?(path) do
      dirs =
        path
        |> File.ls!()
        |> Enum.filter(&File.dir?(Path.join(path, &1)))
        |> Enum.map(&Path.join(prefix, &1))

      {:ok, dirs}
    else
      {:error, :not_found}
    end
  end

  @impl true
  def list_files(path) do
    full_path = Path.join(Netflixir.Storage.storage_bucket(), path)

    if File.exists?(full_path) do
      entries =
        full_path
        |> File.ls!()
        |> Enum.map(fn entry ->
          entry_path = Path.join(full_path, entry)
          relative_path = Path.join(path, entry)
          stat = File.stat!(entry_path)

          %{
            key: relative_path,
            last_modified: stat.mtime,
            size: stat.size
          }
        end)

      {:ok, entries}
    else
      {:error, :not_found}
    end
  end

  @impl true
  def get_private_url(path) do
    full_path =
      Path.join(Netflixir.Storage.storage_bucket(), path)

    if File.exists?(full_path) do
      {:ok, path}
    else
      {:error, :not_found}
    end
  end

  @impl true
  def get_cached_url(path, _expires_in, _cache_hash) do
    get_private_url(path)
  end

  @impl true
  def download(path, local_path) do
    source_path = Path.join(Netflixir.Storage.storage_bucket(), path)

    if File.exists?(source_path) do
      File.mkdir_p!(Path.dirname(local_path))
      File.cp!(source_path, local_path)
      {:ok, local_path}
    else
      {:error, :not_found}
    end
  end

  @impl true
  def upload(local_path, path) do
    if File.exists?(local_path) do
      destination = Path.join(Netflixir.Storage.storage_bucket(), path)
      File.mkdir_p!(Path.dirname(destination))
      File.cp!(local_path, destination)
      {:ok, "file://#{Path.expand(destination)}"}
    else
      {:error, :not_found}
    end
  end
end
