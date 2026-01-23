defmodule Jalka2026Web.FootballLive.Games do
  use Jalka2026Web, :live_view

  alias Jalka2026Web.Resolvers.FootballResolver

  @impl true
  def mount(_params, _session, socket) do
    matches = FootballResolver.list_matches()
    {:ok, assign(socket, matches: matches)}
  end
end
