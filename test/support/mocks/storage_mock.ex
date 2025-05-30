defmodule Netflixir.Storage.DefaultMock do
  @moduledoc """
  Default implementation for Storage mock.
  """

  @behaviour Netflixir.Storage

  @impl true
  def list_directories(_prefix) do
    {:ok,
     [
       "test_processed_videos/test-video-1/",
       "test_processed_videos/awesome-movie/",
       "test_processed_videos/documentary/"
     ]}
  end

  @impl true
  def list_files(_path) do
    {:ok, [Netflixir.StorageFixtures.file_info_fixture()]}
  end

  @impl true
  def get_private_url(path) do
    {:ok, path}
  end

  @impl true
  def get_cached_url(path, expires_in, _cache_hash) do
    {:ok, "https://test.storage.com/test-bucket/#{path}?expires=#{expires_in}&hash=test123"}
  end

  @impl true
  def download(_path, local_path) do
    File.write!(local_path, "test content")
    {:ok, local_path}
  end

  @impl true
  def upload(_local_path, path, _cacheable? \\ true) do
    {:ok, "https://test.storage.com/test-bucket/#{path}"}
  end

  @impl true
  def upload_binary(_local_path_or_binary, path, _cacheable? \\ true) do
    {:ok, "https://test.storage.com/test-bucket/#{path}"}
  end
end
