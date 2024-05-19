defmodule Jalka2024Web.UserPredictionLive.Playoffs do
  use Phoenix.LiveView

  alias Jalka2024Web.Resolvers.FootballResolver
  alias Jalka2024Web.LiveHelpers

  @impl true
  def mount(_params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)
    {:ok, add_teams(socket)}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2024Web.PredictionView, "playoffs.html", assigns)

  @impl true
  def handle_event("toggle-team", user_params, socket) do
    FootballResolver.change_playoff_prediction(%{
      user_id: socket.assigns.current_user.id,
      team_id: String.to_integer(user_params["team"]),
      phase: String.to_integer(user_params["phase"]),
      include: user_params["value"] == "on"
    })

    {:noreply, add_teams(socket)}
  end

  defp add_predictions(teams_with_group, predictions, phase) do
    teams_with_group
    |> Enum.map(fn {group, teams} ->
      teams =
        Enum.map(teams, fn {id, name} ->
          if Enum.member?(predictions[phase], id) do
            {id, name, "checked"}
          else
            {id, name, ""}
          end
        end)

      {group, teams}
    end)
  end

  defp add_predictions_without_group(teams_without_group, predictions, phase) do
    teams_without_group
    |> Enum.map(fn {id, name} ->
      if Enum.member?(predictions[phase], id) do
        {id, name, "checked"}
      else
        {id, name, ""}
      end
    end)
  end

  defp get_teams_from_predictions(teams_with_group, predictions, phase) do
    teams_with_group
    |> Enum.reduce([], fn {_group, teams}, acc ->
      [teams | acc]
    end)
    |> List.flatten()
    |> Enum.reduce([], fn {id, name}, acc ->
      if Enum.member?(predictions[phase], id) do
        [{id, name} | acc]
      else
        acc
      end
    end)
  end

  defp count_left_with_group(teams_with_group) do
    teams_with_group
    |> Enum.map(fn {_group, teams} ->
      teams
    end)
    |> List.flatten()
    |> count_left
  end

  defp count_left(teams) do
    teams
    |> Enum.count(fn {_id, _name, checked} ->
      checked == "checked"
    end)
  end

  defp is_disabled(count_left) do
    if count_left == 0 do
      "disabled"
    else
      ""
    end
  end

  defp add_teams(socket) do
    predictions = FootballResolver.get_playoff_predictions(socket.assigns.current_user.id)
    teams = FootballResolver.get_teams_by_group()

    teams16 =
      teams
      |> add_predictions(predictions, 16)

    teams8 =
      teams
      |> get_teams_from_predictions(predictions, 16)
      |> add_predictions_without_group(predictions, 8)

    teams4 =
      teams
      |> get_teams_from_predictions(predictions, 8)
      |> add_predictions_without_group(predictions, 4)

    teams2 =
      teams
      |> get_teams_from_predictions(predictions, 4)
      |> add_predictions_without_group(predictions, 2)

    teams1 =
      teams
      |> get_teams_from_predictions(predictions, 2)
      |> add_predictions_without_group(predictions, 1)

    left16 = 16 - count_left_with_group(teams16)
    left8 = 8 - count_left(teams8)
    left4 = 4 - count_left(teams4)
    left2 = 2 - count_left(teams2)
    left1 = 1 - count_left(teams1)

    progress = 31 - left16 - left8 - left4 - left2 - left1

    predictions_done =
      if progress != 31 do
        "button-outline"
      end

    if progress == 31 do
      Jalka2024.Leaderboard.recalc_leaderboard()
    end

    assign(socket,
      teams16: teams16,
      left16: left16,
      disabled16: is_disabled(left16),
      teams8: teams8,
      left8: left8,
      disabled8: is_disabled(left8),
      teams4: teams4,
      left4: left4,
      disabled4: is_disabled(left4),
      teams2: teams2,
      left2: left2,
      disabled2: is_disabled(left2),
      teams1: teams1,
      left1: left1,
      disabled1: is_disabled(left1),
      predictions_done: predictions_done
    )
  end
end
