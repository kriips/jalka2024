defmodule Jalka2024Web.FootballLive.Games do
  use Phoenix.LiveView

  alias Jalka2024Web.Resolvers.FootballResolver

  @impl true
  def mount(_params, _session, socket) do
    matches = FootballResolver.list_matches()
    {:ok, assign(socket, matches: matches)}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2024Web.GamesView, "games.html", assigns)
end
