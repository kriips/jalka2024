defmodule Jalka2026Web.Resolvers.FootballResolver do
  alias Jalka2026.{Football}

  def list_matches_by_group(group) do
    Football.get_matches_by_group("Alagrupp #{group}")
  end

  def list_matches() do
    Football.get_matches()
  end

  def list_finished_matches() do
    Football.get_finished_matches()
  end

  def list_playoff_results() do
    Football.get_playoff_results()
  end

  def list_match(id) do
    Football.get_match(id)
  end

  def update_match(%{"away_score" => away_score, "home_score" => home_score, "game_id" => game_id}) do
    Football.update_match_score(
      String.to_integer(game_id),
      String.to_integer(home_score),
      String.to_integer(away_score)
    )

    Jalka2026.Leaderboard.recalc_leaderboard()
  end

  def update_playoff_result(%{"team_name" => team_name, "phase" => phase}) do
    Football.update_playoff_result(
      String.to_integer(phase),
      Football.get_team_by_name(team_name) |> hd() |> Map.get(:id)
    )

    Jalka2026.Leaderboard.recalc_leaderboard()
  end

  def get_prediction(%{match_id: match_id, user_id: user_id}) do
    Football.get_prediction_by_user_match(user_id, match_id)
  end

  def get_predictions_by_match_result(match_id) do
    Football.get_predictions_by_match(match_id)
    |> group_by_result()
  end

  def get_predictions_by_user(user_id) do
    Football.get_predictions_by_user(user_id)
    |> Enum.sort(fn prediction1, prediction2 ->
      NaiveDateTime.compare(prediction1.match.date, prediction2.match.date) != :gt
    end)
  end

  def change_prediction_score(%{
        match_id: match_id,
        user_id: user_id,
        score: {home_score, away_score}
      }) do
    Football.change_score(%{
      user_id: user_id,
      match_id: match_id,
      home_score: home_score,
      away_score: away_score,
      result: calculate_result(home_score, away_score)
    })
  end

  def change_playoff_prediction(%{
        user_id: user_id,
        team_id: team_id,
        phase: phase,
        include: include
      }) do
    if include do
      Football.add_playoff_prediction(%{
        user_id: user_id,
        team_id: team_id,
        phase: phase
      })
    else
      Football.remove_playoff_prediction(%{
        user_id: user_id,
        team_id: team_id,
        phase: phase
      })
    end
  end

  def get_teams_by_group() do
    teams = %{
      "A" => [],
      "B" => [],
      "C" => [],
      "D" => [],
      "E" => [],
      "F" => [],
      "G" => [],
      "H" => [],
      "I" => [],
      "J" => [],
      "K" => [],
      "L" => []
    }

    Football.get_teams()
    |> Enum.reduce(teams, fn team, acc ->
      group = team.group
      Map.put(acc, group, [{team.id, team.name} | acc[group]])
    end)
  end

  def filled_predictions(user_id) do
    user_predictions = %{
      "Alagrupp A" => 0,
      "Alagrupp B" => 0,
      "Alagrupp C" => 0,
      "Alagrupp D" => 0,
      "Alagrupp E" => 0,
      "Alagrupp F" => 0,
      "Alagrupp G" => 0,
      "Alagrupp H" => 0,
      "Alagrupp I" => 0,
      "Alagrupp J" => 0,
      "Alagrupp K" => 0,
      "Alagrupp L" => 0
    }

    Football.get_predictions_by_user(user_id)
    |> Enum.reduce(user_predictions, fn prediction, acc ->
      group = prediction.match.group
      Map.put(acc, group, acc[group] + 1)
    end)
  end

  def get_playoff_predictions(user_id) do
    user_playoff_predictions = %{
      32 => [],
      16 => [],
      8 => [],
      4 => [],
      2 => [],
      1 => []
    }

    Football.get_playoff_predictions_by_user(user_id)
    |> Enum.reduce(user_playoff_predictions, fn prediction, acc ->
      Map.put(acc, prediction.phase, [prediction.team_id | acc[prediction.phase]])
    end)
  end

  def get_playoff_predictions_with_team_names(user_id) do
    user_playoff_predictions = %{
      32 => [],
      16 => [],
      8 => [],
      4 => [],
      2 => [],
      1 => []
    }

    Football.get_playoff_predictions_by_user(user_id)
    |> Enum.reduce(user_playoff_predictions, fn prediction, acc ->
      Map.put(acc, prediction.phase, [prediction.team.name | acc[prediction.phase]])
    end)
  end

  def get_playoff_predictions() do
    Football.get_playoff_predictions()
    |> group_by_phase()
    |> group_by_team()
    |> add_playoff_result()
    |> sort_by_count()
    |> sort_by_phase()
  end

  def calculate_result(home_score, away_score) do
    cond do
      home_score > away_score -> "home"
      home_score < away_score -> "away"
      home_score == away_score -> "draw"
    end
  end

  def add_correctness(user_predictions) do
    user_predictions
    |> Enum.map(fn user_prediction ->
      correct_result =
        if user_prediction.match.finished do
          user_prediction.result == user_prediction.match.result
        else
          false
        end

      correct_score =
        if correct_result do
          user_prediction.match.home_score == user_prediction.home_score &&
            user_prediction.match.away_score == user_prediction.away_score
        else
          false
        end

      {user_prediction, correct_result, correct_score}
    end)
  end

  def add_playoff_correctness(user_playoff_predictions) do
    user_playoff_predictions
    |> Enum.reduce(%{}, fn {phase, team_names}, acc ->
      modified_team_names =
        team_names
        |> Enum.map(fn team_name ->
          if team_reached_phase(team_name, phase) do
            "<b style=\"color:green\">" <> team_name <> "</b>"
          else
            team_name
          end
        end)

      Map.put(acc, phase, modified_team_names)
    end)
  end

  defp group_by_result(predictions) do
    predictions
    |> Enum.group_by(& &1.result, & &1)
  end

  defp group_by_phase(predictions) do
    playoff_predictions = %{
      1 => [],
      2 => [],
      4 => [],
      8 => [],
      16 => [],
      32 => []
    }

    predictions
    |> Enum.reduce(playoff_predictions, fn prediction, acc ->
      Map.put(acc, prediction.phase, [
        %{team_name: prediction.team.name, user_name: prediction.user.name}
        | acc[prediction.phase]
      ])
    end)
  end

  defp group_by_team(predictions) do
    predictions
    |> Enum.map(fn {phase, user_prediction} ->
      {phase, Enum.group_by(user_prediction, & &1.team_name, & &1.user_name) |> Map.to_list()}
    end)
  end

  defp add_playoff_result(predictions) do
    predictions
    |> Enum.map(fn {phase, user_predictions} ->
      {phase, add_playoff_result_to_predictions(phase, user_predictions)}
    end)
  end

  defp add_playoff_result_to_predictions(phase, user_predictions) do
    modified_predictions =
      Enum.map(user_predictions, fn {team_name, users} ->
        {team_name, team_reached_phase(team_name, phase), users}
      end)

    modified_predictions
  end

  defp team_reached_phase(team_name, phase) do
    team_id = Football.get_team_by_name(team_name) |> hd() |> Map.get(:id)
    Football.get_playoff_result_by_phase_team(phase, team_id) != nil
  end

  defp sort_by_count(predictions) do
    predictions
    |> Enum.map(fn {phase, user_predictions} ->
      {
        phase,
        user_predictions
        |> Enum.sort(fn {_team_name1, _reached_phase1, users1},
                        {_team_name2, _reached_phase2, users2} ->
          Enum.count(users1) >= Enum.count(users2)
        end)
      }
    end)
  end

  defp sort_by_phase(predictions) do
    predictions
    |> Enum.sort(fn {phase1, _pred1}, {phase2, _pred2} ->
      phase1 >= phase2
    end)
  end
end
