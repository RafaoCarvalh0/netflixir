defmodule NetflixirWeb.AuthLive.LoginLive do
  use NetflixirWeb, :live_view
  alias Netflixir.Auth.AuthService

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case AuthService.authenticate_user(user_params) do
      {:ok, %{user: user, token: token}} ->
        {:noreply,
         socket
         |> assign_new(:current_user, fn -> user end)
         |> push_event("set-jwt-cookie", %{token: token})}

      {:error, error} when error in [:not_found, :invalid_password] ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid username or password")
         |> assign(form: to_form(user_params, as: :user))}
    end
  end
end
