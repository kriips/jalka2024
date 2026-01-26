defmodule Jalka2026Web.Resolvers.FootballResolverTest do
  use Jalka2026.DataCase

  alias Jalka2026Web.Resolvers.FootballResolver
  import Jalka2026.FootballFixtures
  import Jalka2026.AccountsFixtures

  describe "calculate_result/2" do
    test "returns 'home' when home score is higher" do
      assert FootballResolver.calculate_result(3, 1) == "home"
      assert FootballResolver.calculate_result(2, 0) == "home"
      assert FootballResolver.calculate_result(5, 4) == "home"
    end

    test "returns 'away' when away score is higher" do
      assert FootballResolver.calculate_result(0, 1) == "away"
      assert FootballResolver.calculate_result(2, 3) == "away"
      assert FootballResolver.calculate_result(1, 5) == "away"
    end

    test "returns 'draw' when scores are equal" do
      assert FootballResolver.calculate_result(0, 0) == "draw"
      assert FootballResolver.calculate_result(1, 1) == "draw"
      assert FootballResolver.calculate_result(3, 3) == "draw"
    end
  end

  describe "list_matches_by_group/1" do
    test "returns matches for given group letter" do
      match = match_fixture(%{group: "Alagrupp B"})

      result = FootballResolver.list_matches_by_group("B")

      assert length(result) >= 1
      match_ids = Enum.map(result, & &1.id)
      assert match.id in match_ids
    end
  end

  describe "list_matches/0" do
    test "returns all matches" do
      match1 = match_fixture()
      match2 = match_fixture()

      result = FootballResolver.list_matches()

      assert length(result) >= 2
      match_ids = Enum.map(result, & &1.id)
      assert match1.id in match_ids
      assert match2.id in match_ids
    end
  end

  describe "list_finished_matches/0" do
    test "returns only finished matches" do
      finished = finished_match_fixture()
      _unfinished = match_fixture()

      result = FootballResolver.list_finished_matches()

      assert length(result) == 1
      assert hd(result).id == finished.id
    end
  end

  describe "list_match/1" do
    test "returns match by id" do
      match = match_fixture()

      result = FootballResolver.list_match(match.id)

      assert result.id == match.id
    end
  end

  describe "get_prediction/1" do
    test "returns prediction for user and match" do
      user = user_fixture()
      match = match_fixture()
      prediction = group_prediction_fixture(%{user: user, match: match})

      result = FootballResolver.get_prediction(%{match_id: match.id, user_id: user.id})

      assert result.id == prediction.id
    end

    test "returns nil when no prediction exists" do
      user = user_fixture()
      match = match_fixture()

      result = FootballResolver.get_prediction(%{match_id: match.id, user_id: user.id})

      assert result == nil
    end
  end

  describe "change_prediction_score/1" do
    test "creates or updates prediction with calculated result" do
      user = user_fixture()
      match = match_fixture()

      result =
        FootballResolver.change_prediction_score(%{
          match_id: match.id,
          user_id: user.id,
          score: {2, 1}
        })

      assert result.home_score == 2
      assert result.away_score == 1
      assert result.result == "home"
    end

    test "correctly sets draw result" do
      user = user_fixture()
      match = match_fixture()

      result =
        FootballResolver.change_prediction_score(%{
          match_id: match.id,
          user_id: user.id,
          score: {1, 1}
        })

      assert result.result == "draw"
    end
  end

  describe "get_predictions_by_user/1" do
    test "returns predictions sorted by match date" do
      user = user_fixture()

      home_team1 = team_fixture()
      away_team1 = team_fixture()
      home_team2 = team_fixture()
      away_team2 = team_fixture()

      match1 = match_fixture(%{home_team: home_team1, away_team: away_team1, date: ~N[2026-06-15 18:00:00]})
      match2 = match_fixture(%{home_team: home_team2, away_team: away_team2, date: ~N[2026-06-10 18:00:00]})

      _prediction1 = group_prediction_fixture(%{user: user, match: match1})
      _prediction2 = group_prediction_fixture(%{user: user, match: match2})

      result = FootballResolver.get_predictions_by_user(user.id)

      assert length(result) == 2
      # Should be sorted by date, earlier first
      assert hd(result).match_id == match2.id
    end
  end

  describe "filled_predictions/1" do
    test "returns count of predictions per group" do
      user = user_fixture()
      match = match_fixture(%{group: "Alagrupp C"})
      _prediction = group_prediction_fixture(%{user: user, match: match})

      result = FootballResolver.filled_predictions(user.id)

      assert result["Alagrupp C"] == 1
      assert result["Alagrupp A"] == 0
    end
  end

  describe "get_playoff_predictions/1" do
    test "returns playoff predictions grouped by phase" do
      user = user_fixture()
      team = team_fixture()
      _prediction = playoff_prediction_fixture(%{user: user, team: team, phase: 16})

      result = FootballResolver.get_playoff_predictions(user.id)

      assert team.id in result[16]
      assert result[8] == []
    end
  end

  describe "change_playoff_prediction/1" do
    test "adds playoff prediction when include is true" do
      user = user_fixture()
      team = team_fixture()

      result =
        FootballResolver.change_playoff_prediction(%{
          user_id: user.id,
          team_id: team.id,
          phase: 8,
          include: true
        })

      assert result.user_id == user.id
      assert result.team_id == team.id
      assert result.phase == 8
    end

    test "removes playoff prediction when include is false" do
      user = user_fixture()
      team = team_fixture()
      _prediction = playoff_prediction_fixture(%{user: user, team: team, phase: 16})

      FootballResolver.change_playoff_prediction(%{
        user_id: user.id,
        team_id: team.id,
        phase: 16,
        include: false
      })

      predictions = FootballResolver.get_playoff_predictions(user.id)
      assert team.id not in predictions[16]
    end
  end

  describe "get_teams_by_group/0" do
    test "returns teams grouped by their group letter" do
      team_a = team_fixture(%{name: "Team A Test", group: "A"})
      team_b = team_fixture(%{name: "Team B Test", group: "B"})

      result = FootballResolver.get_teams_by_group()

      assert {team_a.id, team_a.name} in result["A"]
      assert {team_b.id, team_b.name} in result["B"]
    end
  end

  describe "add_correctness/1" do
    test "adds correctness flags to predictions" do
      home_team = team_fixture()
      away_team = team_fixture()

      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 2,
          away_score: 1
        })

      user = user_fixture()

      # Create a prediction with correct result but wrong score
      correct_result_prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 3,
          away_score: 0
        })

      result = FootballResolver.add_correctness([correct_result_prediction])

      [{prediction, correct_result, correct_score}] = result
      assert prediction.id == correct_result_prediction.id
      assert correct_result == true
      assert correct_score == false
    end

    test "marks exact score predictions as correct" do
      home_team = team_fixture()
      away_team = team_fixture()

      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 2,
          away_score: 1
        })

      user = user_fixture()

      # Create a prediction with exact score match
      exact_prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 2,
          away_score: 1
        })

      result = FootballResolver.add_correctness([exact_prediction])

      [{_prediction, correct_result, correct_score}] = result
      assert correct_result == true
      assert correct_score == true
    end

    test "marks wrong result predictions as incorrect" do
      home_team = team_fixture()
      away_team = team_fixture()

      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 2,
          away_score: 1
        })

      user = user_fixture()

      # Create a prediction with wrong result (away win instead of home win)
      wrong_prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 0,
          away_score: 2
        })

      result = FootballResolver.add_correctness([wrong_prediction])

      [{_prediction, correct_result, correct_score}] = result
      assert correct_result == false
      assert correct_score == false
    end
  end
end
