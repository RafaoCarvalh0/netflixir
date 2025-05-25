defmodule NetflixirWeb.AuthLive.LoginLive do
  use NetflixirWeb, :live_view

  import Phoenix.LiveView

  alias NetflixirWeb.Auth

  def mount(_params, session, socket) do
    current_user = Map.get(session, "current_user")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(form: to_form(%{}, as: :user))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Auth.authenticate_user(user_params) do
      {:ok, %{user: user, token: token}} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> push_event("set-jwt-cookie", %{token: token})
         |> redirect(to: "/")}

      {:error, error} when error in [:not_found, :invalid_password] ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid username or password")
         |> assign(form: to_form(user_params, as: :user))}
    end
  end
end
