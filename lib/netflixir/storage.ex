defmodule Netflixir.Storage do
  @moduledoc """
  Module responsible for managing file uploads and downloads using S3-compatible storage.
  """

  @doc """
  Uploads a file to the storage service.

  ## Parameters
    - file: Can be a %Plug.Upload{} (Phoenix upload) or a file path
    - bucket: Storage bucket name
    - path: File path/name in the bucket (e.g., "videos/my-video.mp4")

  ## Examples
      iex> Storage.upload(%Plug.Upload{path: "/tmp/video.mp4"}, "my-bucket", "videos/video1.mp4")
      {:ok, "https://storage-endpoint.com/my-bucket/videos/video1.mp4"}

      iex> Storage.upload("/local/path/video.mp4", "my-bucket", "videos/video2.mp4")
      {:ok, "https://storage-endpoint.com/my-bucket/videos/video2.mp4"}
  """
  @spec upload(Plug.Upload.t() | String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def upload(file, bucket, path) do
    file_binary = get_file_binary(file)

    try do
      bucket
      |> ExAws.S3.put_object(path, file_binary)
      |> ExAws.request()
      |> case do
        {:ok, _response} ->
          url = get_file_url(bucket, path)
          {:ok, url}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Downloads a file from the storage service.

  ## Parameters
    - bucket: Storage bucket name
    - path: File path/name in the bucket
    - local_path: Local path where the file will be saved (optional)

  ## Examples
      iex> Storage.download("my-bucket", "videos/video1.mp4", "/downloads/video1.mp4")
      {:ok, "/downloads/video1.mp4"}

      iex> Storage.download("my-bucket", "videos/not-found.mp4")
      {:error, :not_found}
  """
  @spec download(String.t(), String.t(), String.t() | nil) ::
          {:ok, String.t()} | {:error, term()}
  def download(bucket, path, local_path \\ nil) do
    local_path = local_path || Path.basename(path)

    try do
      case ExAws.S3.get_object(bucket, path) |> ExAws.request() do
        {:ok, %{body: body}} ->
          File.write!(local_path, body)
          {:ok, local_path}

        {:error, {:http_error, 404, _}} ->
          {:error, :not_found}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Gets a private presigned URL for a file in the storage.
  Returns a presigned URL that is valid for 2 hours.

  ## Parameters
    - bucket: Storage bucket name
    - path: File path/name in the bucket

  ## Example
      iex> Storage.get_private_url("my-bucket", "files/document.pdf")
      {:ok, "https://storage-endpoint.com/my-bucket/files/document.pdf?..."}
  """
  @spec get_private_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def get_private_url(bucket, path) do
    config = Application.get_env(:ex_aws, :s3)
    two_hours_in_seconds = 7200

    ExAws.S3.presigned_url(config, :get, bucket, path, expires_in: two_hours_in_seconds)
  end

  @doc """
  Gets a cached presigned URL for a file in the storage.
  Returns a presigned URL with cache control headers and cache hash for invalidation.

  ## Parameters
    - bucket: Storage bucket name
    - path: File path/name in the bucket
    - expires_in: URL expiration time in seconds
    - cache_hash: Hash for cache invalidation

  ## Example
      iex> Storage.get_cached_url("my-bucket", "images/photo.jpg", 3600, "abc123")
      {:ok, "https://storage-endpoint.com/my-bucket/images/photo.jpg?..."}
  """
  @spec get_cached_url(String.t(), String.t(), pos_integer(), String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def get_cached_url(bucket, path, expires_in, cache_hash) do
    query_params = %{
      "response-cache-control" => "public, max-age=#{expires_in}, immutable",
      "response-expires" =>
        DateTime.utc_now() |> DateTime.add(expires_in, :second) |> DateTime.to_string(),
      "v" => cache_hash
    }

    config = Application.get_env(:ex_aws, :s3)

    ExAws.S3.presigned_url(config, :get, bucket, path,
      expires_in: expires_in,
      query_params: query_params
    )
  end

  @doc """
  Deletes a file from the storage service.

  ## Parameters
    - bucket: Storage bucket name
    - path: File path/name in the bucket

  ## Example
      iex> Storage.delete("my-bucket", "videos/to-delete.mp4")
      {:ok, %{}}
  """
  @spec delete(String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def delete(bucket, path) do
    bucket
    |> ExAws.S3.delete_object(path)
    |> ExAws.request()
  end

  @doc """
  Lists files in a bucket.

  ## Parameters
    - bucket: Storage bucket name
    - prefix: Filter by prefix (optional)

  ## Example
      iex> Storage.list_files("my-bucket", "videos/")
      {:ok, ["videos/video1.mp4", "videos/video2.mp4"]}
  """
  @spec list_files(String.t(), String.t() | nil) :: {:ok, [String.t()]} | {:error, term()}
  def list_files(bucket, prefix \\ nil) do
    try do
      bucket
      |> ExAws.S3.list_objects(prefix: prefix)
      |> ExAws.request()
      |> case do
        {:ok, %{body: %{contents: contents}}} ->
          files = Enum.map(contents, & &1.key)
          {:ok, files}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Creates a directory-like prefix in the storage.
  Note: S3-compatible storage doesn't have real directories,
  this creates an empty object with the directory name as prefix.

  ## Parameters
    - bucket: Storage bucket name
    - directory: Directory path (e.g., "videos/" or "videos/2024/")

  ## Example
      iex> Storage.create_directory("my-bucket", "videos/")
      {:ok, "videos/"}
  """
  @spec create_directory(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def create_directory(bucket, directory) do
    directory = if String.ends_with?(directory, "/"), do: directory, else: directory <> "/"

    try do
      bucket
      |> ExAws.S3.put_object(directory, "")
      |> ExAws.request()
      |> case do
        {:ok, _response} -> {:ok, directory}
        {:error, error} -> {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Lists all "directories" (prefixes) in a bucket or within a specific prefix.

  ## Parameters
    - bucket: Storage bucket name
    - prefix: Parent directory prefix (optional)

  ## Example
      iex> Storage.list_directories("my-bucket", "videos/")
      {:ok, ["videos/2024/", "videos/archived/"]}
  """
  @spec list_directories(String.t(), String.t() | nil) :: {:ok, [String.t()]} | {:error, term()}
  def list_directories(bucket, prefix \\ nil) do
    delimiter = "/"
    prefix = if prefix && !String.ends_with?(prefix, "/"), do: prefix <> "/", else: prefix

    try do
      bucket
      |> ExAws.S3.list_objects(prefix: prefix, delimiter: delimiter)
      |> ExAws.request()
      |> case do
        {:ok, %{body: %{common_prefixes: prefixes}}} when not is_nil(prefixes) ->
          directories = Enum.map(prefixes, & &1.prefix)
          {:ok, directories}

        {:ok, %{body: %{common_prefixes: nil}}} ->
          {:ok, []}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Checks if a "directory" exists in the storage.

  ## Parameters
    - bucket: Storage bucket name
    - directory: Directory path to check

  ## Example
      iex> Storage.directory_exists?("my-bucket", "videos/")
      true
  """
  @spec directory_exists?(String.t(), String.t()) :: boolean()
  def directory_exists?(bucket, directory) do
    directory = if String.ends_with?(directory, "/"), do: directory, else: directory <> "/"

    case list_files(bucket, directory) do
      {:ok, [_ | _]} -> true
      {:ok, []} -> false
      {:error, _} -> false
    end
  end

  defp get_file_binary(%Plug.Upload{path: path}), do: File.read!(path)
  defp get_file_binary(path) when is_binary(path), do: File.read!(path)
  defp get_file_binary(data), do: data

  defp get_file_url(bucket, path) do
    endpoint = Application.get_env(:ex_aws, :s3)[:host]
    "https://#{endpoint}/#{bucket}/#{path}"
  end
end
