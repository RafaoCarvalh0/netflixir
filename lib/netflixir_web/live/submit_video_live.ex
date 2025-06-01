defmodule NetflixirWeb.SubmitVideoLive do
  use NetflixirWeb, :live_view

  alias Netflixir.Videos.Services.VideoService

  @allowed_video_extensions ~w(.mp4)
  @allowed_thumbnail_extensions ~w(.jpg .jpeg .png .webp)
  @max_video_size_in_bytes 50_000_000
  @max_thumbnail_size_in_bytes 2_000_000

  def mount(_params, session, socket) do
    current_user = Map.get(session, "current_user")

    {:ok,
     socket
     |> assign(current_user: current_user, flash_message: nil)
     |> allow_upload(:video,
       accept: @allowed_video_extensions,
       max_file_size: @max_video_size_in_bytes
     )
     |> allow_upload(:thumbnail,
       accept: @allowed_thumbnail_extensions,
       max_file_size: @max_thumbnail_size_in_bytes
     )}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  def handle_event("save", %{"video_name" => name}, socket) do
    video_entries =
      consume_uploaded_entries(socket, :video, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    thumbnail_entries =
      consume_uploaded_entries(socket, :thumbnail, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    case {video_entries, thumbnail_entries} do
      {[video_bin], [thumb_bin]} ->
        case upload_video(socket, video_bin, thumb_bin, name) do
          {:ok, :success} ->
            {:noreply,
             socket
             |> put_flash(:info, "Video uploaded successfully!")
             |> assign(:flash_message, %{type: :success, message: "Video uploaded successfully!"})}

          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, reason)
             |> assign(:flash_message, %{type: :error, message: reason})}
        end

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Please select both video and thumbnail files")
         |> assign(:flash_message, %{
           type: :error,
           message: "Please select both video and thumbnail files"
         })}
    end
  end

  def upload_video(socket, video_binary, thumbnail_binary, file_name) do
    case socket.assigns.current_user do
      nil ->
        {:error, "You must be logged in to upload videos"}

      current_user ->
        VideoService.upload_submitted_video_and_thumbnail(
          video_binary,
          thumbnail_binary,
          file_name,
          current_user.username
        )
    end
  end
end
