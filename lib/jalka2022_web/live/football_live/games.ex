defmodule Jalka2022Web.FootballLive.Games do
  use Phoenix.LiveView

  alias Jalka2022Web.Resolvers.FootballResolver
  alias Jalka2022Web.LiveHelpers

  @impl true
  def mount(_params, session, socket) do
    matches = FootballResolver.list_matches()
    {:ok, assign(socket, matches: matches)}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2022Web.GamesView, "games.html", assigns)
end
