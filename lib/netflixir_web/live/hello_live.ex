defmodule NetflixirWeb.HelloLive do
  use NetflixirWeb, :live_view

  def mount(_params, _session, socket) do
    dbg(socket)
    {:ok, assign(socket, :message, "Hello World!")}
  end
end
