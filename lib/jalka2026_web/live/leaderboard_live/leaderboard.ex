defmodule Jalka2026Web.LeaderboardLive.Leaderboard do
  use Jalka2026Web, :live_view

  alias Jalka2026.Leaderboard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, leaderboard: Leaderboard.get_leaderboard())}
  end
end
