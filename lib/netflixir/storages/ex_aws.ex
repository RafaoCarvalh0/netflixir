defmodule Netflixir.Storage.ExAws do
  @moduledoc """
  ExAws-based implementation of the Storage behaviour.
  """
  @behaviour Netflixir.Storage

  @impl true
  def list_directories(prefix) do
    ExAws.S3.list_objects(Netflixir.Storage.storage_bucket(),
      prefix: prefix,
      delimiter: "/"
    )
    |> ExAws.request()
    |> case do
      {:ok, %{body: %{common_prefixes: prefixes}}} ->
        {:ok, Enum.map(prefixes, & &1.prefix)}

      {:error, {:http_error, 404, _}} ->
        {:error, :not_found}

      error ->
        error
    end
  end

  @impl true
  def list_files(path) do
    ExAws.S3.list_objects(Netflixir.Storage.storage_bucket(), prefix: path)
    |> ExAws.request()
    |> case do
      {:ok, %{body: %{contents: contents}}} ->
        files =
          Enum.map(contents, fn file ->
            %{
              key: file.key,
              last_modified: file.last_modified,
              size: file.size
            }
          end)

        {:ok, files}

      error ->
        error
    end
  end

  @impl true
  def get_private_url(path) do
    ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, Netflixir.Storage.storage_bucket(), path)
  end

  @impl true
  def get_cached_url(path, expires_in, cache_hash) do
    config = ExAws.Config.new(:s3)

    ExAws.S3.presigned_url(
      config,
      :get,
      Netflixir.Storage.storage_bucket(),
      path,
      expires_in: expires_in,
      query_params: [{"hash", cache_hash}]
    )
  end

  @impl true
  def download(path, local_path) do
    ExAws.S3.download_file(Netflixir.Storage.storage_bucket(), path, local_path)
    |> ExAws.request()
    |> case do
      {:ok, :done} -> {:ok, local_path}
      error -> error
    end
  end

  @impl true
  def upload(local_path_or_binary, path, cacheable? \\ true) do
    cache_for_one_week = "public, max-age=604800"

    headers =
      if cacheable? do
        [{"cache-control", cache_for_one_week}]
      else
        []
      end

    local_path_or_binary
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(Netflixir.Storage.storage_bucket(), path, headers: headers)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, "#{bucket_url()}/#{path}"}
      error -> error
    end
  end

  @impl true
  def upload_binary(local_path_or_binary, path, cacheable? \\ true) do
    cache_for_one_week = "public, max-age=604800"

    headers =
      if cacheable? do
        [{"cache-control", cache_for_one_week}]
      else
        []
      end

    Netflixir.Storage.storage_bucket()
    |> ExAws.S3.put_object(path, local_path_or_binary, headers: headers)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, "#{bucket_url()}/#{path}"}
      error -> error
    end
  end

  defp bucket_url do
    config = ExAws.Config.new(:s3)
    "#{config.scheme}#{config.host}"
  end
end
