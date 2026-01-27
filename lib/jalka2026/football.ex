defmodule Jalka2026.Football do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Jalka2026.Repo
  alias Jalka2026.Football.{Match, GroupPrediction, PlayoffPrediction, Team, PlayoffResult, HistoricalMatch}
  alias Jalka2026Web.Resolvers.FootballResolver

  ## Database getters

  def get_matches_by_group(group) when is_binary(group) do
    IO.inspect("Getting matches by group")
    IO.inspect(group)
    query =
      from(m in Match,
        where: m.group == ^group,
        order_by: m.date,
        preload: [:home_team, :away_team]
      )

    Repo.all(query)
  end

  def get_finished_matches() do
    query =
      from(m in Match,
        where: m.finished == true,
        order_by: m.date
      )

    Repo.all(query)
  end

  def get_playoff_results() do
    query = from(pr in PlayoffResult)

    Repo.all(query)
  end

  def get_matches() do
    query =
      from(m in Match,
        order_by: m.date,
        preload: [:home_team, :away_team]
      )

    Repo.all(query)
    |> Enum.map(fn match ->
      %Match{match | date: Timex.shift(match.date, hours: +2)}
    end)
  end

  def get_match(id) do
    Repo.get_by(Match, id: id) |> Repo.preload([:home_team, :away_team])
  end

  def get_prediction_by_user_match(user_id, match_id) do
    Repo.get_by(GroupPrediction, user_id: user_id, match_id: match_id)
  end

  def get_predictions_by_match(match_id) do
    query =
      from(gp in GroupPrediction,
        where: gp.match_id == ^match_id,
        preload: [:user]
      )

    Repo.all(query)
  end

  def get_team_by_name(team_name) do
    query =
      from(t in Team,
        where: t.name == ^team_name
      )

    Repo.all(query)
  end

  def get_predictions_by_user(user_id) do
    query =
      from(gp in GroupPrediction,
        where: gp.user_id == ^user_id,
        preload: [match: [:home_team, :away_team]]
      )

    Repo.all(query)
  end

  def get_playoff_predictions() do
    query =
      from(pp in PlayoffPrediction,
        preload: [:user, :team]
      )

    Repo.all(query)
  end

  def get_playoff_predictions_by_user(user_id) do
    query =
      from(pp in PlayoffPrediction,
        where: pp.user_id == ^user_id,
        preload: [:team]
      )

    Repo.all(query)
  end

  def get_playoff_prediction_by_user_phase_team(user_id, phase, team_id) do
    Repo.get_by(PlayoffPrediction, user_id: user_id, team_id: team_id, phase: phase)
  end

  def get_playoff_result_by_phase_team(phase, team_id) do
    Repo.get_by(PlayoffResult, team_id: team_id, phase: phase)
  end

  def delete_playoff_predictions_by_user_team(user_id, team_id, phase) do
    query =
      from(pp in PlayoffPrediction,
        where: pp.user_id == ^user_id and pp.team_id == ^team_id and pp.phase <= ^phase
      )

    Repo.delete_all(query)
  end

  def change_score(
        %{
          user_id: user_id,
          match_id: match_id,
          home_score: _home_score,
          away_score: _away_score
        } = attrs
      ) do
    case get_prediction_by_user_match(user_id, match_id) do
      %GroupPrediction{} = prediction ->
        prediction |> GroupPrediction.create_changeset(attrs) |> Repo.update!()

      nil ->
        %GroupPrediction{} |> GroupPrediction.create_changeset(attrs) |> Repo.insert!()
    end
  end

  def update_match_score(game_id, home_score, away_score) do
    case get_match(game_id) do
      %Match{} = match ->
        match
        |> Match.create_changeset(%{
          home_score: home_score,
          away_score: away_score,
          finished: true,
          result: FootballResolver.calculate_result(home_score, away_score)
        })
        |> Repo.update!()

      nil ->
        IO.inspect("Incorrect game id")
        IO.inspect(game_id)
    end
  end

  def update_playoff_result(phase, team_id) do
    case get_playoff_result_by_phase_team(phase, team_id) do
      %PlayoffResult{} = result ->
        result |> Repo.delete!()

      nil ->
        %PlayoffResult{}
        |> PlayoffResult.create_changeset(%{phase: phase, team_id: team_id})
        |> Repo.insert!()
    end
  end

  def get_teams() do
    Team
    |> Repo.all()
  end

  def add_playoff_prediction(%{user_id: user_id, team_id: team_id, phase: phase} = attrs) do
    case get_playoff_prediction_by_user_phase_team(user_id, phase, team_id) do
      %PlayoffPrediction{} = prediction ->
        prediction |> PlayoffPrediction.create_changeset(attrs) |> Repo.update!()

      nil ->
        %PlayoffPrediction{} |> PlayoffPrediction.create_changeset(attrs) |> Repo.insert!()
    end
  end

  def remove_playoff_prediction(%{user_id: user_id, team_id: team_id, phase: phase}) do
    delete_playoff_predictions_by_user_team(user_id, team_id, phase)
  end

  ## Historical Matchup Data

  @doc """
  Get all historical matches between two teams (by team code).
  Returns matches where either team was home or away.
  """
  def get_historical_matchup(team1_code, team2_code) do
    query =
      from(hm in HistoricalMatch,
        where:
          (hm.home_team_code == ^team1_code and hm.away_team_code == ^team2_code) or
            (hm.home_team_code == ^team2_code and hm.away_team_code == ^team1_code),
        order_by: [desc: hm.date]
      )

    Repo.all(query)
  end

  @doc """
  Get all World Cup matches between two teams.
  """
  def get_world_cup_matchup(team1_code, team2_code) do
    query =
      from(hm in HistoricalMatch,
        where:
          hm.is_world_cup == true and
            ((hm.home_team_code == ^team1_code and hm.away_team_code == ^team2_code) or
               (hm.home_team_code == ^team2_code and hm.away_team_code == ^team1_code)),
        order_by: [desc: hm.date]
      )

    Repo.all(query)
  end

  @doc """
  Get historical statistics between two teams.
  Returns a map with wins, draws, losses, goals for/against for team1.
  """
  def get_historical_stats(team1_code, team2_code) do
    matches = get_historical_matchup(team1_code, team2_code)

    initial = %{
      total_matches: 0,
      team1_wins: 0,
      team2_wins: 0,
      draws: 0,
      team1_goals: 0,
      team2_goals: 0
    }

    Enum.reduce(matches, initial, fn match, acc ->
      {team1_goals, team2_goals} =
        if match.home_team_code == team1_code do
          {match.home_score, match.away_score}
        else
          {match.away_score, match.home_score}
        end

      win_status =
        cond do
          team1_goals > team2_goals -> :team1_win
          team2_goals > team1_goals -> :team2_win
          true -> :draw
        end

      %{
        acc
        | total_matches: acc.total_matches + 1,
          team1_wins: acc.team1_wins + if(win_status == :team1_win, do: 1, else: 0),
          team2_wins: acc.team2_wins + if(win_status == :team2_win, do: 1, else: 0),
          draws: acc.draws + if(win_status == :draw, do: 1, else: 0),
          team1_goals: acc.team1_goals + team1_goals,
          team2_goals: acc.team2_goals + team2_goals
      }
    end)
  end

  @doc """
  Get recent form - last N matches for a team.
  """
  def get_team_recent_form(team_code, limit \\ 5) do
    query =
      from(hm in HistoricalMatch,
        where: hm.home_team_code == ^team_code or hm.away_team_code == ^team_code,
        order_by: [desc: hm.date],
        limit: ^limit
      )

    matches = Repo.all(query)

    Enum.map(matches, fn match ->
      {goals_for, goals_against, opponent_code, opponent_name, is_home} =
        if match.home_team_code == team_code do
          {match.home_score, match.away_score, match.away_team_code, match.away_team_name, true}
        else
          {match.away_score, match.home_score, match.home_team_code, match.home_team_name, false}
        end

      result =
        cond do
          goals_for > goals_against -> "W"
          goals_against > goals_for -> "L"
          true -> "D"
        end

      %{
        date: match.date,
        opponent_code: opponent_code,
        opponent_name: opponent_name,
        goals_for: goals_for,
        goals_against: goals_against,
        result: result,
        is_home: is_home,
        competition: match.competition
      }
    end)
  end

  @doc """
  Get all World Cup matches for a team (historical World Cup record).
  """
  def get_team_world_cup_history(team_code) do
    query =
      from(hm in HistoricalMatch,
        where:
          hm.is_world_cup == true and
            (hm.home_team_code == ^team_code or hm.away_team_code == ^team_code),
        order_by: [desc: hm.date]
      )

    Repo.all(query)
  end

  @doc """
  Get World Cup statistics for a team.
  """
  def get_team_world_cup_stats(team_code) do
    matches = get_team_world_cup_history(team_code)

    initial = %{
      matches_played: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goals_for: 0,
      goals_against: 0
    }

    Enum.reduce(matches, initial, fn match, acc ->
      {goals_for, goals_against} =
        if match.home_team_code == team_code do
          {match.home_score, match.away_score}
        else
          {match.away_score, match.home_score}
        end

      result =
        cond do
          goals_for > goals_against -> :win
          goals_against > goals_for -> :loss
          true -> :draw
        end

      %{
        acc
        | matches_played: acc.matches_played + 1,
          wins: acc.wins + if(result == :win, do: 1, else: 0),
          draws: acc.draws + if(result == :draw, do: 1, else: 0),
          losses: acc.losses + if(result == :loss, do: 1, else: 0),
          goals_for: acc.goals_for + goals_for,
          goals_against: acc.goals_against + goals_against
      }
    end)
  end
end
