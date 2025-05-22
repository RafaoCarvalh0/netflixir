defmodule Netflixir.StorageFixtures do
  @moduledoc """
  This module contains helper functions for testing storage operations.
  """

  @fixed_datetime ~U[2024-03-10 15:30:00Z]

  @doc """
  Returns a map with common test file info.
  """
  def file_info_fixture(attrs \\ %{}) do
    Map.merge(
      %{
        key: "test/file.mp4",
        last_modified: @fixed_datetime,
        size: 1024
      },
      attrs
    )
  end

  @doc """
  Configures the storage mock with default implementations.
  """
  def setup_storage_mock_defaults do
    Mox.stub_with(Netflixir.Storage.Mock, Netflixir.Storage.DefaultMock)
  end
end
