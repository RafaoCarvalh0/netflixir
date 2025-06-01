defmodule Netflixir.Videos.Processors.ThumbnailProcessor do
  @moduledoc """
  Provides utilities for processing and resizing video thumbnails.
  """

  alias Netflixir.Utils.FfmpegUtils
  alias Netflixir.Utils.DirectoryAndFileUtils

  @thumbnail_width 854
  @thumbnail_height 480
  @min_image_width 100
  @min_image_height 100

  @doc """
  Resizes a thumbnail binary to 854x480 (16:9 SD) using ffmpeg.
  Returns {:ok, resized_binary} or {:error, reason}.
  """
  @spec thumbnail_from_binary(binary()) :: {:ok, binary()} | {:error, String.t()}
  def thumbnail_from_binary(image_binary) do
    if is_image_binary?(image_binary) do
      tmp_in =
        Path.join(System.tmp_dir!(), "thumb_in_#{:erlang.unique_integer([:positive])}.webp")

      tmp_out =
        Path.join(System.tmp_dir!(), "thumb_out_#{:erlang.unique_integer([:positive])}.webp")

      args = build_ffmpeg_resize_args(tmp_in, tmp_out, @thumbnail_width, @thumbnail_height)

      with :ok <- File.write(tmp_in, image_binary),
           {:ok, :valid} <- validate_image_dimensions(tmp_in),
           {:ok, :success} <- FfmpegUtils.run_ffmpeg(args),
           {:ok, thumbnail_binary} <- File.read(tmp_out) do
        remove_tmp_files(tmp_in, tmp_out)
        {:ok, thumbnail_binary}
      else
        {:error, reason} ->
          remove_tmp_files(tmp_in, tmp_out)
          {:error, "Failed to resize thumbnail: #{inspect(reason)}"}
      end
    else
      {:error,
       "Failed to resize thumbnail: Provided binary is not a valid image format (supported: PNG, JPEG, WebP)"}
    end
  end

  defp build_ffmpeg_resize_args(input_path, output_path, width, height) do
    force_overwrite = ["-y"]
    input_file = ["-i", input_path]

    # -vf ...: video filter chain
    #   scale=WxH:force_original_aspect_ratio=decrease: resize to fit within WxH, keep aspect
    #   pad=WxH:(ow-iw)/2:(oh-ih)/2: pad with black to fill WxH if needed
    video_filter = [
      "-vf",
      "scale=#{width}:#{height}:force_original_aspect_ratio=decrease,pad=#{width}:#{height}:(ow-iw)/2:(oh-ih)/2"
    ]

    List.flatten([
      force_overwrite,
      input_file,
      video_filter,
      output_path
    ])
  end

  defp remove_tmp_files(tmp_in, tmp_out) do
    DirectoryAndFileUtils.remove_file_if_exists(tmp_in)
    DirectoryAndFileUtils.remove_file_if_exists(tmp_out)
  end

  defp is_image_binary?(binary) do
    is_webp?(binary) or is_png?(binary) or is_jpeg_or_jpg?(binary)
  end

  defp is_webp?(<<0x52, 0x49, 0x46, 0x46, _::binary-size(4), 0x57, 0x45, 0x42, 0x50, _::binary>>),
    do: true

  defp is_webp?(_), do: false

  defp is_png?(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: true
  defp is_png?(_), do: false

  defp is_jpeg_or_jpg?(<<0xFF, 0xD8, _::binary>>), do: true
  defp is_jpeg_or_jpg?(_), do: false

  defp validate_image_dimensions(image_path) do
    dimension_check_args = [
      "-v",
      "error",
      "-select_streams",
      "v:0",
      "-show_entries",
      "stream=width,height",
      "-of",
      "csv=s=x:p=0",
      image_path
    ]

    case get_image_dimensions(dimension_check_args) do
      {:ok, width, height} when width >= @min_image_width and height >= @min_image_height ->
        {:ok, :valid}

      {:ok, _width, _height} ->
        {:error,
         "Failed to resize thumbnail: Image dimensions must be at least #{@min_image_width}x#{@min_image_height} pixels."}

      {:error, reason} ->
        {:error, "Failed to resize thumbnail: #{inspect(reason)}"}
    end
  end

  defp get_image_dimensions(dimension_check_args) do
    case System.cmd("ffprobe", dimension_check_args, stderr_to_stdout: true) do
      {dimensions, 0} ->
        dimension_string_separator = "x"

        [width_string, height_string] =
          dimensions
          |> String.trim()
          |> String.split(dimension_string_separator)

        {width, ""} = Integer.parse(width_string)
        {height, ""} = Integer.parse(height_string)

        {:ok, width, height}

      {output, _} ->
        {:error, "Could not determine image dimensions: #{inspect(output)}"}

      _ ->
        {:error, "Could not parse image dimensions"}
    end
  end
end
