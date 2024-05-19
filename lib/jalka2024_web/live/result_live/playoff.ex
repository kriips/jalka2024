defmodule Jalka2024Web.ResultLive.Playoff do
  use Phoenix.LiveView

  alias Jalka2024Web.Resolvers.FootballResolver
  alias Jalka2024Web.LiveHelpers

  @impl true
  def mount(_params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)
    {:ok, socket}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2024Web.ResultView, "playoff.html", assigns)

  @impl true
  def handle_event("save", values, socket) do
    FootballResolver.update_playoff_result(values["result"])
    {:noreply, socket}
  end
end
