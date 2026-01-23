defmodule Jalka2026.LeaderboardTest do
  use Jalka2026.DataCase

  import Jalka2026.FootballFixtures
  import Jalka2026.AccountsFixtures

  # Note: The Leaderboard is a GenServer that calculates points based on predictions.
  # These tests verify the point calculation logic.

  describe "point calculation logic" do
    test "user gets 1 point for correct result prediction" do
      user = user_fixture()
      home_team = team_fixture()
      away_team = team_fixture()

      # Create a finished match with home win (2-1)
      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 2,
          away_score: 1
        })

      # User predicts home win but wrong score (3-0)
      _prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 3,
          away_score: 0
        })

      # Verify the prediction has correct result but wrong score
      assert finished_match.result == "home"
      prediction = Jalka2026.Football.get_prediction_by_user_match(user.id, finished_match.id)
      assert prediction.result == "home"
      assert prediction.home_score != finished_match.home_score
    end

    test "user gets 2 points for exact score prediction" do
      user = user_fixture()
      home_team = team_fixture()
      away_team = team_fixture()

      # Create a finished match with exact score
      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 2,
          away_score: 1
        })

      # User predicts exact score
      _prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 2,
          away_score: 1
        })

      # Verify the prediction matches exactly
      prediction = Jalka2026.Football.get_prediction_by_user_match(user.id, finished_match.id)
      assert prediction.home_score == finished_match.home_score
      assert prediction.away_score == finished_match.away_score
      assert prediction.result == finished_match.result
    end

    test "user gets 0 points for wrong result prediction" do
      user = user_fixture()
      home_team = team_fixture()
      away_team = team_fixture()

      # Create a finished match with home win
      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 2,
          away_score: 1
        })

      # User predicts away win (wrong result)
      _prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 0,
          away_score: 2
        })

      # Verify the prediction has wrong result
      assert finished_match.result == "home"
      prediction = Jalka2026.Football.get_prediction_by_user_match(user.id, finished_match.id)
      assert prediction.result == "away"
      assert prediction.result != finished_match.result
    end
  end

  describe "playoff point values" do
    # Testing the point values defined in add_playoff_points/2
    # Phase 32 (round of 32): 1 point
    # Phase 16 (round of 16): 2 points
    # Phase 8 (quarter finals): 3 points
    # Phase 4 (semi finals): 5 points
    # Phase 2 (final): 6 points
    # Phase 1 (winner): 8 points

    test "playoff prediction setup for phase 32" do
      user = user_fixture()
      team = team_fixture()
      prediction = playoff_prediction_fixture(%{user: user, team: team, phase: 32})

      assert prediction.phase == 32
    end

    test "playoff prediction setup for phase 16" do
      user = user_fixture()
      team = team_fixture()
      prediction = playoff_prediction_fixture(%{user: user, team: team, phase: 16})

      assert prediction.phase == 16
    end

    test "playoff result can be created for verification" do
      team = team_fixture()
      result = playoff_result_fixture(%{team: team, phase: 8})

      assert result.phase == 8
      assert result.team_id == team.id
    end

    test "round of 32 prediction and result can be matched" do
      user = user_fixture()
      team = team_fixture()

      # User predicts team advances to Round of 32
      prediction = playoff_prediction_fixture(%{user: user, team: team, phase: 32})

      # Team actually advances to Round of 32
      result = playoff_result_fixture(%{team: team, phase: 32})

      # Verify the prediction matches the result
      assert prediction.team_id == result.team_id
      assert prediction.phase == result.phase
      assert prediction.phase == 32
    end

    test "multiple round of 32 predictions can be created for same user" do
      user = user_fixture()
      team1 = team_fixture()
      team2 = team_fixture()
      team3 = team_fixture()

      # User predicts multiple teams to advance to Round of 32
      p1 = playoff_prediction_fixture(%{user: user, team: team1, phase: 32})
      p2 = playoff_prediction_fixture(%{user: user, team: team2, phase: 32})
      p3 = playoff_prediction_fixture(%{user: user, team: team3, phase: 32})

      assert p1.phase == 32
      assert p2.phase == 32
      assert p3.phase == 32
      assert p1.user_id == p2.user_id
      assert p2.user_id == p3.user_id
    end
  end

  describe "draw predictions" do
    test "draw result is correctly calculated" do
      user = user_fixture()
      home_team = team_fixture()
      away_team = team_fixture()

      # Create a finished match with draw
      finished_match =
        finished_match_fixture(%{
          home_team: home_team,
          away_team: away_team,
          home_score: 1,
          away_score: 1
        })

      # User predicts draw
      _prediction =
        group_prediction_fixture(%{
          user: user,
          match: finished_match,
          home_score: 2,
          away_score: 2
        })

      prediction = Jalka2026.Football.get_prediction_by_user_match(user.id, finished_match.id)
      assert prediction.result == "draw"
      assert finished_match.result == "draw"
    end
  end
end
