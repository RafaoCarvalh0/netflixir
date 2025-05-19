defmodule Netflixir.Repo do
  use Ecto.Repo,
    otp_app: :netflixir,
    adapter: Ecto.Adapters.Postgres
end
