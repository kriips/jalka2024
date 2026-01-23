defmodule Jalka2026Web.FootballLive.Game do
  use Jalka2026Web, :live_view

  alias Jalka2026Web.Resolvers.FootballResolver

  @impl true
  def mount(params, _session, socket) do
    case FootballResolver.list_match(params["id"]) do
      nil ->
        {:ok, socket |> redirect(to: "/football/games")}

      match ->
        {:ok,
         socket
         |> assign(
           predictions: FootballResolver.get_predictions_by_match_result(params["id"]),
           match: match
         )}
    end
  end
end
