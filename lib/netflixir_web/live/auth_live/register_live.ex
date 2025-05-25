defmodule NetflixirWeb.AuthLive.RegisterLive do
  use NetflixirWeb, :live_view
  alias Netflixir.Users.Services.UserService

  def mount(_params, session, socket) do
    current_user = Map.get(session, "current_user")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(form: to_form(%{}, as: :user))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case UserService.register_user(user_params) |> dbg() do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created! Please sign in.")
         |> redirect(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end
end
