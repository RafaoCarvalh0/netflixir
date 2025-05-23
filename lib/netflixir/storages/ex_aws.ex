defmodule Netflixir.Storage.ExAws do
  @moduledoc """
  ExAws-based implementation of the Storage behaviour.
  """
  @behaviour Netflixir.Storage

  defp bucket_name do
    Application.get_env(:netflixir, :storage_bucket)
  end

  @impl true
  def list_directories(prefix) do
    ExAws.S3.list_objects(bucket_name(),
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
    ExAws.S3.list_objects(bucket_name(), prefix: path)
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
    ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, bucket_name(), path)
  end

  @impl true
  def get_cached_url(path, expires_in, cache_hash) do
    config = ExAws.Config.new(:s3)

    ExAws.S3.presigned_url(
      config,
      :get,
      bucket_name(),
      path,
      expires_in: expires_in,
      query_params: [{"hash", cache_hash}]
    )
  end

  @impl true
  def download(path, local_path) do
    ExAws.S3.download_file(bucket_name(), path, local_path)
    |> ExAws.request()
    |> case do
      {:ok, :done} -> {:ok, local_path}
      error -> error
    end
  end

  @impl true
  def upload(local_path, path) do
    local_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket_name(), path)
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
