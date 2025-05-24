defmodule NetflixirWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use NetflixirWeb, :controller
      use NetflixirWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths,
    do: ~w(assets fonts images favicon.ico robots.txt videos storage service-worker.js)

  @doc """
  Handles paths for static files, converting local paths to the correct static path based on environment.

  In development, converts local paths to use the static file server path.
  In production, keeps remote URLs unchanged.

  ## Examples

      iex> thumbnail_path("/thumbnails/video.webp")
      "/storage/dev/thumbnails/video.webp"

      iex> thumbnail_path("https://storage.com/thumbnails/video.webp")
      "https://storage.com/thumbnails/video.webp"
  """
  def thumbnail_path(path) do
    if remote_url?(path) do
      path
    else
      Path.join(static_storage_path(), String.replace_prefix(path, "/", ""))
    end
  end

  def remote_url?(path) do
    case URI.new(path) do
      {:ok, %URI{scheme: scheme}} when not is_nil(scheme) -> true
      _ -> false
    end
  end

  defp static_storage_path do
    storage_bucket = Application.get_env(:netflixir, :storage_bucket)
    "/storage/#{Path.basename(storage_bucket)}"
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: NetflixirWeb.Layouts]

      use Gettext, backend: NetflixirWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {NetflixirWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: NetflixirWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import NetflixirWeb.CoreComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: NetflixirWeb.Endpoint,
        router: NetflixirWeb.Router,
        statics: NetflixirWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
