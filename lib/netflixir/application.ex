defmodule Netflixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NetflixirWeb.Telemetry,
      Netflixir.Repo,
      {DNSCluster, query: Application.get_env(:netflixir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Netflixir.PubSub},
      # Start the EventRegister GenServer
      Netflixir.EventRegister,
      # Start a worker by calling: Netflixir.Worker.start_link(arg)
      # {Netflixir.Worker, arg},
      # Start to serve requests, typically the last entry
      NetflixirWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Netflixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NetflixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
