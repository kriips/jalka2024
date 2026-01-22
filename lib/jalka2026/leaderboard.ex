defmodule Jalka2026.Leaderboard do
  use GenServer

  alias Jalka2026Web.Resolvers.{FootballResolver, AccountsResolver}
  alias Jalka2026.Football
  alias Jalka2026.Accounts.User

  def start_link(_leaderboard \\ %{}) do
    GenServer.start_link(__MODULE__, recalculate_leaderboard(), name: __MODULE__)
  end

  def init(leaderboard), do: {:ok, leaderboard}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:get_leaderboard, _from, leaderboard) do
    {:reply, leaderboard, leaderboard}
  end

  def handle_call(:recalc_leaderboard, _from, _leaderboard) do
    leaderboard = recalculate_leaderboard()
    {:reply, leaderboard, leaderboard}
  end

  def get_leaderboard, do: GenServer.call(__MODULE__, :get_leaderboard)
  def recalc_leaderboard, do: GenServer.call(__MODULE__, :recalc_leaderboard)

  defp recalculate_leaderboard() do
    finished_matches = FootballResolver.list_finished_matches()
    playoff_results = FootballResolver.list_playoff_results()

    AccountsResolver.list_users()
    |> Enum.map(&calculate_points(&1, finished_matches))
    |> Enum.map(&calculate_playoff_points(&1, playoff_results))
    |> Enum.sort(fn {_id1, _name1, _gpoints1, _ppoints1, points1},
                    {_id2, _name2, _gpoints2, _ppoints2, points2} ->
      points1 >= points2
    end)
    |> add_rank()
  end

  defp calculate_playoff_points({user_id, user_name, group_points}, playoff_results) do
    playoff_predictions = FootballResolver.get_playoff_predictions(user_id)

    playoff_points =
      playoff_results
      |> Enum.reduce(0, fn playoff_result, points ->
        if Map.get(playoff_predictions, playoff_result.phase)
           |> Enum.member?(playoff_result.team_id) do
          add_playoff_points(points, playoff_result.phase)
        else
          points
        end
      end)

    {user_id, user_name, group_points, playoff_points, group_points + playoff_points}
  end

  defp calculate_points(%User{} = user, finished_matches) do
    points =
      finished_matches
      |> Enum.reduce(0, fn finished_match, points ->
        group_prediction =
          Football.get_prediction_by_user_match(user.id, finished_match.id)
          |> sanitize()

        add_points(points, finished_match, group_prediction)
      end)

    {user.id, user.name, points}
  end

  defp add_playoff_points(points, phase) do
    case phase do
      32 -> points + 1
      16 -> points + 2
      8 -> points + 3
      4 -> points + 5
      2 -> points + 6
      1 -> points + 8
    end
  end

  defp add_points(points, _finished_match, nil) do
    points
  end

  defp add_points(points, finished_match, group_prediction) do
    if finished_match.result == group_prediction.result do
      if finished_match.home_score == group_prediction.home_score &&
           finished_match.away_score == group_prediction.away_score do
        points + 2
      else
        points + 1
      end
    else
      points
    end
  end

  defp sanitize(nil) do
    nil
  end

  defp sanitize(group_prediction) do
    if group_prediction.home_score && group_prediction.away_score &&
         is_nil(group_prediction.result) do
      FootballResolver.change_prediction_score(%{
        match_id: group_prediction.match_id,
        user_id: group_prediction.user_id,
        score: {group_prediction.home_score, group_prediction.away_score}
      })
    else
      group_prediction
    end
  end

  defp add_rank(users, rank \\ 1, index \\ 1, acc \\ [])

  defp add_rank([{id, name, gpoints, ppoints, points} | users], rank, index, acc) do
    add_rank(users, rank, index + 1, points, acc ++ [{id, rank, name, gpoints, ppoints, points}])
  end

  defp add_rank([], _rank, _index, []) do
    []
  end

  defp add_rank([{id, name, gpoints, ppoints, points} | users], rank, index, prev_points, acc) do
    new_rank =
      if points == prev_points do
        rank
      else
        index
      end

    add_rank(
      users,
      new_rank,
      index + 1,
      points,
      acc ++ [{id, new_rank, name, gpoints, ppoints, points}]
    )
  end

  defp add_rank([], _rank, _index, _prev_points, acc) do
    acc
  end
end
