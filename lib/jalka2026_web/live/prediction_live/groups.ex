defmodule Jalka2026Web.UserPredictionLive.Groups do
  use Jalka2026Web, :live_view

  alias Jalka2026Web.Resolvers.FootballResolver
  alias Jalka2026.Football
  alias Jalka2026.Football.{Match}
  alias Jalka2026.Football.MatchSimulation, as: Simulator
  alias Jalka2026.Football.GroupScenarios

  @groups ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]

  @impl true
  def mount(params, session, socket) do
    group = Map.get(params, "group")
    socket = Jalka2026Web.LiveHelpers.assign_defaults(session, socket)

    predictions =
      FootballResolver.list_matches_by_group(group)
      |> Enum.map(fn match -> add_score(match, socket) end)

    # Load historical matchup data for each match
    historical_data = load_historical_data(predictions)

    {:ok,
     assign(socket,
       group: group,
       predictions: predictions,
       predictions_done: predictions_done_count(predictions),
       focused_match_index: 0,
       focused_side: "home",
       prev_group: get_prev_group(group),
       next_group: get_next_group(group),
       historical_data: historical_data,
       # New state for match analysis dropdown
       expanded_match_id: nil,
       active_analysis_tab: nil,
       simulation_data: nil,
       detailed_history: nil,
       simulating: false,
       # Group scenarios state
       show_scenarios: false,
       scenario_data: nil,
       team_requirements: nil
     )}
  end

  defp get_prev_group(group) do
    case Enum.find_index(@groups, &(&1 == group)) do
      nil -> nil
      0 -> nil
      index -> Enum.at(@groups, index - 1)
    end
  end

  defp get_next_group(group) do
    case Enum.find_index(@groups, &(&1 == group)) do
      nil -> nil
      index when index == length(@groups) - 1 -> nil
      index -> Enum.at(@groups, index + 1)
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => key} = params, socket) do
    match_id = params["match-id"]
    side = params["side"]
    home_score = params["home-score"]
    away_score = params["away-score"]

    case key do
      "ArrowUp" ->
        handle_event("inc-score", %{
          "match" => match_id,
          "side" => side,
          "home-score" => home_score,
          "away-score" => away_score
        }, socket)

      "ArrowDown" ->
        handle_event("dec-score", %{
          "match" => match_id,
          "side" => side,
          "home-score" => home_score,
          "away-score" => away_score
        }, socket)

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("inc-score", user_params, socket) do
    if Jalka2026Web.LiveHelpers.predictions_open?() do
      changed_score =
        case user_params["side"] do
          "home" ->
            {inc_score(user_params["home-score"]), nullify_hyphen(user_params["away-score"])}

          "away" ->
            {nullify_hyphen(user_params["home-score"]), inc_score(user_params["away-score"])}
        end

      match_id = String.to_integer(user_params["match"])

      updated_prediction =
        FootballResolver.change_prediction_score(%{
          match_id: match_id,
          user_id: socket.assigns.current_user.id,
          side: user_params["side"],
          score: changed_score
        })

      {:noreply, socket |> update_prediction(match_id, updated_prediction)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Ennustamine on suletud - turniir on alanud")
       |> redirect(to: "/")}
    end
  end

  def handle_event("dec-score", user_params, socket) do
    if Jalka2026Web.LiveHelpers.predictions_open?() do
      changed_score =
        case user_params["side"] do
          "home" ->
            {dec_score(user_params["home-score"]), nullify_hyphen(user_params["away-score"])}

          "away" ->
            {nullify_hyphen(user_params["home-score"]), dec_score(user_params["away-score"])}
        end

      match_id = String.to_integer(user_params["match"])

      updated_prediction =
        FootballResolver.change_prediction_score(%{
          match_id: match_id,
          user_id: socket.assigns.current_user.id,
          side: user_params["side"],
          score: changed_score
        })

      {:noreply, socket |> update_prediction(match_id, updated_prediction)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Ennustamine on suletud - turniir on alanud")
       |> redirect(to: "/")}
    end
  end

  # Event handlers for match analysis dropdown
  def handle_event("toggle_analysis", %{"match-id" => match_id_str}, socket) do
    match_id = String.to_integer(match_id_str)

    if socket.assigns.expanded_match_id == match_id do
      # Close the dropdown
      {:noreply, assign(socket,
        expanded_match_id: nil,
        active_analysis_tab: nil,
        simulation_data: nil,
        detailed_history: nil,
        simulating: false
      )}
    else
      # Open the dropdown, default to simulation tab
      {:noreply, assign(socket,
        expanded_match_id: match_id,
        active_analysis_tab: "simulation",
        simulation_data: nil,
        detailed_history: nil,
        simulating: false
      )}
    end
  end

  def handle_event("select_analysis_tab", %{"tab" => tab, "match-id" => match_id_str}, socket) do
    match_id = String.to_integer(match_id_str)

    socket = assign(socket, active_analysis_tab: tab)

    # Lazy load data based on tab
    case tab do
      "simulation" ->
        if socket.assigns.simulation_data == nil do
          {match, _} = Enum.find(socket.assigns.predictions, fn {m, _} -> m.id == match_id end)
          send(self(), {:load_simulation, match.home_team.code, match.away_team.code})
          {:noreply, assign(socket, simulating: true)}
        else
          {:noreply, socket}
        end

      "history" ->
        if socket.assigns.detailed_history == nil do
          {match, _} = Enum.find(socket.assigns.predictions, fn {m, _} -> m.id == match_id end)
          send(self(), {:load_history, match.home_team.code, match.away_team.code})
          {:noreply, socket}
        else
          {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("close_analysis", _params, socket) do
    {:noreply, assign(socket,
      expanded_match_id: nil,
      active_analysis_tab: nil,
      simulation_data: nil,
      detailed_history: nil,
      simulating: false
    )}
  end

  # Group scenarios events
  def handle_event("toggle_scenarios", _params, socket) do
    if socket.assigns.show_scenarios do
      {:noreply, assign(socket, show_scenarios: false)}
    else
      # Lazy load scenarios data
      if socket.assigns.scenario_data == nil do
        scenario_data = GroupScenarios.calculate_scenarios(socket.assigns.group)
        team_requirements = GroupScenarios.analyze_team_requirements(socket.assigns.group)
        {:noreply, assign(socket,
          show_scenarios: true,
          scenario_data: scenario_data,
          team_requirements: team_requirements
        )}
      else
        {:noreply, assign(socket, show_scenarios: true)}
      end
    end
  end

  defp add_score(%Match{} = match, socket) do
    scores =
      case FootballResolver.get_prediction(%{
             match_id: match.id,
             user_id: socket.assigns.current_user.id
           }) do
        %{home_score: home_score, away_score: away_score} -> {home_score, away_score}
        _ -> {"-", "-"}
      end

    {match, scores}
  end

  defp inc_score(score) do
    case score do
      "-" -> 1
      x -> String.to_integer(x) + 1
    end
  end

  defp dec_score(score) do
    case score do
      "-" -> 0
      "0" -> 0
      x -> String.to_integer(x) - 1
    end
  end

  defp nullify_hyphen(score) do
    case score do
      "-" -> 0
      x -> String.to_integer(x)
    end
  end

  defp update_prediction(socket, match_id, updated_prediction) do
    predictions =
      socket.assigns.predictions
      |> Enum.map(fn {match, _score} = prediction ->
        if match.id == match_id do
          {match, {updated_prediction.home_score, updated_prediction.away_score}}
        else
          prediction
        end
      end)

    socket
    |> assign(predictions: predictions, predictions_done: predictions_done_count(predictions))
  end

  defp predictions_done_count(predictions) do
    case Enum.count(predictions, fn {_pred, {home_score, away_score}} ->
           away_score != "-" or home_score != "-"
         end) < 6 do
      true -> "button-outline"
      _ -> ""
    end
  end

  defp load_historical_data(predictions) do
    predictions
    |> Enum.map(fn {match, _scores} ->
      home_code = match.home_team.code
      away_code = match.away_team.code

      stats = Football.get_historical_stats(home_code, away_code)
      world_cup_matches = Football.get_world_cup_matchup(home_code, away_code)

      {match.id, %{
        stats: stats,
        world_cup_matches: world_cup_matches
      }}
    end)
    |> Map.new()
  end

  def format_date(date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

  # Handle async data loading
  @impl true
  def handle_info({:load_simulation, team1_code, team2_code}, socket) do
    results = Simulator.simulate_match(team1_code, team2_code, simulations: 10_000)
    team1_breakdown = Simulator.get_strength_breakdown(team1_code, team2_code)
    team2_breakdown = Simulator.get_strength_breakdown(team2_code, team1_code)

    {:noreply, assign(socket,
      simulation_data: %{
        results: results,
        team1_breakdown: team1_breakdown,
        team2_breakdown: team2_breakdown
      },
      simulating: false
    )}
  end

  def handle_info({:load_history, team1_code, team2_code}, socket) do
    matches = Football.get_historical_matchup(team1_code, team2_code)
    world_cup_matches = Football.get_world_cup_matchup(team1_code, team2_code)
    stats = Football.get_historical_stats(team1_code, team2_code)
    team1_form = Football.get_team_recent_form(team1_code, 5)
    team2_form = Football.get_team_recent_form(team2_code, 5)
    team1_wc_stats = Football.get_team_world_cup_stats(team1_code)
    team2_wc_stats = Football.get_team_world_cup_stats(team2_code)

    {:noreply, assign(socket,
      detailed_history: %{
        matches: matches,
        world_cup_matches: world_cup_matches,
        stats: stats,
        team1_form: team1_form,
        team2_form: team2_form,
        team1_wc_stats: team1_wc_stats,
        team2_wc_stats: team2_wc_stats
      }
    )}
  end

  # Helper functions for templates
  def probability_color(percentage) do
    cond do
      percentage >= 10.0 -> "probability-high"
      percentage >= 5.0 -> "probability-medium"
      percentage >= 2.0 -> "probability-low"
      percentage > 0 -> "probability-minimal"
      true -> "probability-zero"
    end
  end

  def strength_color(value) do
    cond do
      value >= 1.2 -> "strength-high"
      value >= 1.0 -> "strength-medium"
      value >= 0.8 -> "strength-low"
      true -> "strength-very-low"
    end
  end

  def format_percentage(value) do
    :erlang.float_to_binary(value, decimals: 1)
  end

  def result_class("W"), do: "result-win"
  def result_class("D"), do: "result-draw"
  def result_class("L"), do: "result-loss"
  def result_class(_), do: ""

  def home_away_indicator(true), do: "(K)"
  def home_away_indicator(false), do: "(V)"

  # Scenario helpers
  def status_class(:qualified), do: "status-qualified"
  def status_class(:eliminated), do: "status-eliminated"
  def status_class(:likely), do: "status-likely"
  def status_class(:possible), do: "status-possible"
  def status_class(:unlikely), do: "status-unlikely"
  def status_class(_), do: ""

  def status_label(:qualified), do: "Kindlalt edasi"
  def status_label(:eliminated), do: "Langenud"
  def status_label(:likely), do: "Tõenäoline"
  def status_label(:possible), do: "Võimalik"
  def status_label(:unlikely), do: "Ebatõenäoline"
  def status_label(_), do: "Teadmata"

  def format_goal_diff(gd) when gd > 0, do: "+#{gd}"
  def format_goal_diff(gd), do: "#{gd}"
end
