defmodule NetflixirWeb.Router do
  use NetflixirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NetflixirWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NetflixirWeb.Plugs.FetchCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug NetflixirWeb.Plugs.AuthPlug
  end

  scope "/", NetflixirWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/watch/:id", WatchLive
    live "/register", AuthLive.RegisterLive
    live "/login", AuthLive.LoginLive

    post "/set_jwt", SessionController, :set_jwt
    get "/logout", SessionController, :logout
    get "/login_success", SessionController, :login_success
  end

  scope "/", NetflixirWeb do
    pipe_through [:browser, :auth]

    live "/hello", HelloLive
  end
end
