defmodule Jalka2026Web.FootballLive.Playoffs do
  use Jalka2026Web, :live_view

  alias Jalka2026Web.Resolvers.FootballResolver

  @impl true
  def mount(_params, _session, socket) do
    predictions = FootballResolver.get_playoff_predictions()
    {:ok, assign(socket, predictions: predictions)}
  end
end
