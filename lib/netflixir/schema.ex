defmodule Netflixir.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias Ecto.Changeset

      @timestamps_opts [{:inserted_at, :created_at}]
    end
  end
end
