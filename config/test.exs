import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :netflixir, Netflixir.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "netflixir_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :netflixir, NetflixirWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Aw/HdZ+Lk86HJtVCJF1YdtBeA3bLQTbTRlF1BFWnhMxk7Wu30F5luYKUAKvU+CyF",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :netflixir, :video_resolutions, [
  %{
    name: "360p",
    resolution: "640x360",
    bitrate: "800k",
    audio_bitrate: "64k",
    bandwidth: "800000"
  }
]
