defmodule Netflixir.Videos.Processors.ThumbnailProcessorTest do
  use ExUnit.Case, async: true
  alias Netflixir.Videos.Processors.ThumbnailProcessor

  @fixtures_path "test/fixtures/images"

  setup do
    cleanup_temp_files()
    :ok
  end

  describe "thumbnail_from_binary/1" do
    test "returns error for invalid image binary" do
      invalid_binary = "not an image"

      assert {:error,
              "Failed to resize thumbnail: Provided binary is not a valid image format (supported: PNG, JPEG, WebP)"} ==
               ThumbnailProcessor.thumbnail_from_binary(invalid_binary)
    end

    test "returns error for image with invalid dimensions" do
      small_image = File.read!("#{@fixtures_path}/small_image.png")
      assert {:error, _} = ThumbnailProcessor.thumbnail_from_binary(small_image)
    end

    test "successfully resizes valid image to webp format" do
      valid_image = File.read!("#{@fixtures_path}/valid_image.png")
      assert {:ok, resized} = ThumbnailProcessor.thumbnail_from_binary(valid_image)
      assert is_binary(resized)

      assert <<0x52, 0x49, 0x46, 0x46, _::binary-size(4), 0x57, 0x45, 0x42, 0x50, _::binary>> =
               resized
    end

    test "cleans up temporary files after successful processing" do
      valid_image = File.read!("#{@fixtures_path}/valid_image.png")
      {:ok, _} = ThumbnailProcessor.thumbnail_from_binary(valid_image)

      assert [] == find_temp_files("thumb_in_")
      assert [] == find_temp_files("thumb_out_")
    end

    test "cleans up temporary files after error" do
      small_image = File.read!("#{@fixtures_path}/small_image.png")
      {:error, _} = ThumbnailProcessor.thumbnail_from_binary(small_image)

      assert [] == find_temp_files("thumb_in_")
      assert [] == find_temp_files("thumb_out_")
    end
  end

  defp find_temp_files(prefix) do
    System.tmp_dir!()
    |> File.ls!()
    |> Enum.filter(&String.starts_with?(&1, prefix))
  end

  defp cleanup_temp_files do
    System.tmp_dir!()
    |> File.ls!()
    |> Enum.filter(&String.starts_with?(&1, "thumb_"))
    |> Enum.each(fn file ->
      File.rm!(Path.join(System.tmp_dir!(), file))
    end)
  end
end
