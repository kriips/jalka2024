defmodule Jalka2026.Football do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Jalka2026.Repo
  alias Jalka2026.Football.{Match, GroupPrediction, PlayoffPrediction, Team, PlayoffResult}
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
end
