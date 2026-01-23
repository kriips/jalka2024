defmodule Jalka2026Web.FootballLive.User do
  use Jalka2026Web, :live_view

  alias Jalka2026Web.Resolvers.{FootballResolver, AccountsResolver}

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(
       predictions:
         FootballResolver.get_predictions_by_user(params["id"])
         |> FootballResolver.add_correctness(),
       user: AccountsResolver.get_user(params["id"]),
       playoff_predictions:
         FootballResolver.get_playoff_predictions_with_team_names(params["id"])
         |> FootballResolver.add_playoff_correctness()
     )}
  end
end
