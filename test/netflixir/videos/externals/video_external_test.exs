defmodule Netflixir.Videos.Externals.VideoExternalTest do
  use ExUnit.Case, async: true

  alias Netflixir.Videos.Externals.VideoExternal

  describe "from_storage/4" do
    test "creates a new video external with all fields" do
      assert %VideoExternal{
               id: "my_awesome_video",
               title: "My Awesome Video",
               created_at: "2024-03-22T10:00:00Z",
               status: "Ready",
               playlist_path: "https://example.com/playlist.m3u8",
               thumbnail: "https://example.com/thumbnail.jpg"
             } =
               VideoExternal.from_storage(
                 "my_awesome_video",
                 "2024-03-22T10:00:00Z",
                 "https://example.com/playlist.m3u8",
                 "https://example.com/thumbnail.jpg"
               )
    end

    test "handles nil created_at" do
      assert %VideoExternal{created_at: nil} =
               VideoExternal.from_storage(
                 "video1",
                 nil,
                 "https://example.com/playlist.m3u8",
                 "https://example.com/thumbnail.jpg"
               )
    end

    test "formats title by capitalizing each word" do
      assert %VideoExternal{title: "Hello World"} =
               VideoExternal.from_storage(
                 "hello_world",
                 nil,
                 "path",
                 "thumb"
               )
    end

    test "formats title handling multiple underscores and hyphens" do
      assert %VideoExternal{title: "My Awesome Video"} =
               VideoExternal.from_storage(
                 "my__awesome--video",
                 nil,
                 "path",
                 "thumb"
               )
    end

    test "formats title handling leading and trailing spaces" do
      assert %VideoExternal{title: "My Video"} =
               VideoExternal.from_storage(
                 " my-video ",
                 nil,
                 "path",
                 "thumb"
               )
    end

    test "formats title handling mixed separators" do
      assert %VideoExternal{title: "My Awesome Video 2024"} =
               VideoExternal.from_storage(
                 "my_awesome-video-2024",
                 nil,
                 "path",
                 "thumb"
               )
    end
  end
end
