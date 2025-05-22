defmodule Netflixir.Storage do
  @moduledoc """
  Defines the behaviour that any storage implementation must follow.
  """

  @type path :: String.t()
  @type file_info :: %{
          key: String.t(),
          last_modified: DateTime.t() | String.t(),
          size: non_neg_integer()
        }

  @callback list_directories(prefix :: path()) ::
              {:ok, [path()]} | {:error, :not_found | term()}

  @callback list_files(path()) ::
              {:ok, [file_info()]} | {:error, term()}

  @callback get_private_url(path()) ::
              {:ok, String.t()} | {:error, term()}

  @callback get_cached_url(path(), expires_in :: pos_integer(), cache_hash :: String.t()) ::
              {:ok, String.t()} | {:error, term()}

  @callback download(path(), local_path :: path()) ::
              {:ok, path()} | {:error, term()}

  @callback upload(local_path :: path(), path()) ::
              {:ok, String.t()} | {:error, term()}

  def list_directories(prefix), do: module().list_directories(prefix)

  def list_files(path), do: module().list_files(path)

  def get_private_url(path), do: module().get_private_url(path)

  def get_cached_url(path, expires_in, cache_hash),
    do: module().get_cached_url(path, expires_in, cache_hash)

  def download(path, local_path), do: module().download(path, local_path)

  def upload(local_path, path), do: module().upload(local_path, path)

  defp module do
    Application.get_env(:netflixir, :storage_module)
  end
end
