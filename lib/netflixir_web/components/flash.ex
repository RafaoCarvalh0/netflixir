defmodule NetflixirWeb.FlashComponent do
  use Phoenix.Component

  attr :flash, :map, required: true

  def render(assigns) do
    ~H"""
    <%= for {type, msg} <- @flash do %>
      <div
        id={"flash-#{type}"}
        phx-hook="AutoHideFlash"
        class="fixed top-0 left-1/2 transform -translate-x-1/2 z-50
               bg-gray-900 text-white px-6 py-4 rounded shadow-lg flex items-center gap-2
               animate-fade-in"
        style="min-width: 300px; max-width: 90vw;"
      >
        <span class="font-bold capitalize">{type}:</span>
        <span>{msg}</span>
        <button
          class="ml-auto text-white hover:text-red-400"
          phx-click="lv:clear-flash"
          phx-value-key={type}
        >
          ✕
        </button>
      </div>
    <% end %>
    """
  end
end
