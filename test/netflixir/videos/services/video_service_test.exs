defmodule Netflixir.Videos.Services.VideoServiceTest do
  use Netflixir.DataCase

  alias Netflixir.StorageFixtures
  alias Netflixir.Videos.Services.VideoService
  alias Netflixir.Storage.Mock, as: StorageMock

  setup do
    StorageFixtures.setup_storage_mock_defaults()
    :ok
  end

  describe "list_available_videos/0" do
    test "returns list of available videos" do
      assert VideoService.list_available_videos() == [
               %Netflixir.Videos.Externals.VideoExternal{
                 created_at: ~U[2024-03-10 15:30:00Z],
                 id: "test-video-1",
                 playlist_path: "test_processed_videos/test-video-1/hls/master.m3u8",
                 status: "Ready",
                 thumbnail:
                   "https://test.storage.com/test-bucket/thumbnails/test-video-1.webp?expires=604800&hash=test123",
                 title: "Test Video 1"
               },
               %Netflixir.Videos.Externals.VideoExternal{
                 created_at: ~U[2024-03-10 15:30:00Z],
                 id: "awesome-movie",
                 playlist_path: "test_processed_videos/awesome-movie/hls/master.m3u8",
                 status: "Ready",
                 thumbnail:
                   "https://test.storage.com/test-bucket/thumbnails/awesome-movie.webp?expires=604800&hash=test123",
                 title: "Awesome Movie"
               },
               %Netflixir.Videos.Externals.VideoExternal{
                 created_at: ~U[2024-03-10 15:30:00Z],
                 id: "documentary",
                 playlist_path: "test_processed_videos/documentary/hls/master.m3u8",
                 status: "Ready",
                 thumbnail:
                   "https://test.storage.com/test-bucket/thumbnails/documentary.webp?expires=604800&hash=test123",
                 title: "Documentary"
               }
             ]
    end

    test "returns empty list when no videos are available" do
      Mox.stub(StorageMock, :list_directories, fn _prefix ->
        {:error, :not_found}
      end)

      assert VideoService.list_available_videos() == []
    end
  end

  describe "get_video_by_id/1" do
    test "returns video when it exists" do
      video_id = "test-video-1"

      assert VideoService.get_video_by_id(video_id) ==
               {
                 :ok,
                 %Netflixir.Videos.Externals.VideoExternal{
                   created_at: ~U[2024-03-10 15:30:00Z],
                   id: "test-video-1",
                   playlist_path: "test_processed_videos/test-video-1/hls/master.m3u8",
                   status: "Ready",
                   thumbnail:
                     "https://test.storage.com/test-bucket/thumbnails/test-video-1.webp?expires=604800&hash=test123",
                   title: "Test Video 1"
                 }
               }
    end

    test "returns error when video does not exist" do
      Mox.stub(StorageMock, :list_files, fn _path ->
        {:ok, []}
      end)

      assert {:error, :not_found} = VideoService.get_video_by_id("non-existent")
    end
  end

  describe "get_signed_url/1" do
    test "returns signed url when successful" do
      path = "test.mp4"
      assert VideoService.get_signed_url(path) == path
    end

    test "returns nil when error occurs" do
      Mox.stub(StorageMock, :get_private_url, fn _path ->
        {:error, "some error"}
      end)

      assert VideoService.get_signed_url("error.mp4") == nil
    end
  end
end
