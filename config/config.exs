# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :netflixir,
  ecto_repos: [Netflixir.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :netflixir, NetflixirWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: NetflixirWeb.ErrorHTML, json: NetflixirWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Netflixir.PubSub,
  live_view: [signing_salt: "pU4LO7Xe"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  netflixir: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  netflixir: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :netflixir, :videos,
  paths: %{
    raw_videos_local_path: "priv/static/videos/raw",
    transcoded_videos_local_path: "priv/static/videos/transcoded",
    intro_video_local_path: "priv/static/videos/intro/intro.mp4"
  },
  storage_bucket: System.get_env("STORAGE_BUCKET"),
  resolutions: %{
    "1080p" => %{
      name: "1080p",
      resolution: "1920x1080",
      bitrate: "5000k",
      audio_bitrate: "192k",
      bandwidth: "5000000"
    },
    "720p" => %{
      name: "720p",
      resolution: "1280x720",
      bitrate: "2800k",
      audio_bitrate: "128k",
      bandwidth: "2800000"
    },
    "480p" => %{
      name: "480p",
      resolution: "854x480",
      bitrate: "1400k",
      audio_bitrate: "96k",
      bandwidth: "1400000"
    },
    "360p" => %{
      name: "360p",
      resolution: "640x360",
      bitrate: "800k",
      audio_bitrate: "64k",
      bandwidth: "800000"
    },
    "240p" => %{
      name: "240p",
      resolution: "426x240",
      bitrate: "400k",
      audio_bitrate: "48k",
      bandwidth: "400000"
    },
    "144p" => %{
      name: "144p",
      resolution: "256x144",
      bitrate: "200k",
      audio_bitrate: "32k",
      bandwidth: "200000"
    }
  }

config :ex_aws,
  access_key_id: System.get_env("B2_KEY_ID"),
  secret_access_key: System.get_env("B2_APP_KEY"),
  region: System.get_env("B2_REGION"),
  s3: [
    scheme: "https://",
    host: System.get_env("B2_HOST"),
    port: System.get_env("B2_PORT")
  ]
