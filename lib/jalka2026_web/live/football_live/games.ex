defmodule Jalka2026Web.FootballLive.Games do
  use Phoenix.LiveView

  alias Jalka2026Web.Resolvers.FootballResolver

  @impl true
  def mount(_params, _session, socket) do
    matches = FootballResolver.list_matches()
    {:ok, assign(socket, matches: matches)}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2026Web.GamesView, "games.html", assigns)
end
