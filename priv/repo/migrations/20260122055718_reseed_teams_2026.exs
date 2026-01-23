defmodule Jalka2026.Repo.Migrations.ReseedTeams2026 do
  use Ecto.Migration
  require Logger
  import Ecto.Query

  # Disable DDL transaction so Repo.insert_all works correctly
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    # Get prefix for file paths
    prefix = case Application.get_env(:jalka2026, :environment) do
      :prod -> "/app/lib/jalka2026-0.1.0"
      _ -> Mix.Project.app_path()
    end

    # Load the updated 2026 teams list
    teams_file = ~c"#{prefix}/priv/repo/data/teams.json"
    teams_data = Jason.decode!(File.read!(teams_file))
    # Handle both old format (flat array) and new format (object with "teams" key)
    teams = if is_list(teams_data), do: teams_data, else: Map.get(teams_data, "teams", [])

    # Load matches to derive team groups (new format doesn't have group in teams.json)
    matches_file = ~c"#{prefix}/priv/repo/data/matches.json"
    matches_data = Jason.decode!(File.read!(matches_file))
    matches = if is_list(matches_data), do: matches_data, else: Map.get(matches_data, "matches", [])

    # Build a map of team_id -> group from matches (GROUP_A -> A, GROUP_B -> B, etc.)
    team_groups = matches
    |> Enum.filter(& &1["stage"] == "GROUP_STAGE")
    |> Enum.flat_map(fn match ->
      group = match["group"] |> String.replace("GROUP_", "")
      [
        {match["homeTeam"]["id"], group},
        {match["awayTeam"]["id"], group}
      ]
    end)
    |> Enum.reject(fn {id, _} -> is_nil(id) end)
    |> Enum.into(%{})

    Logger.info("Reseeding teams with #{length(teams)} teams for 2026 tournament...")

    # Get IDs of teams in the new data
    new_team_ids = Enum.map(teams, & &1["id"])

    # Delete old data in correct order to respect foreign key constraints:
    # 1. group_prediction (references matches)
    # 2. playoff_predictions (references teams)
    # 3. playoff_results (references teams)
    # 4. matches (references teams)
    # 5. teams

    execute("""
    DELETE FROM group_prediction
    WHERE match_id IN (
      SELECT id FROM matches
      WHERE home_team_id NOT IN (#{Enum.join(new_team_ids, ",")})
         OR away_team_id NOT IN (#{Enum.join(new_team_ids, ",")})
    )
    """)

    execute("""
    DELETE FROM playoff_predictions
    WHERE team_id NOT IN (#{Enum.join(new_team_ids, ",")})
    """)

    execute("""
    DELETE FROM playoff_results
    WHERE team_id NOT IN (#{Enum.join(new_team_ids, ",")})
    """)

    execute("""
    DELETE FROM matches
    WHERE home_team_id NOT IN (#{Enum.join(new_team_ids, ",")})
       OR away_team_id NOT IN (#{Enum.join(new_team_ids, ",")})
    """)

    execute("""
    DELETE FROM teams
    WHERE id NOT IN (#{Enum.join(new_team_ids, ",")})
    """)

    # Upsert all teams from the JSON file
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.each(teams, fn team ->
      team_id = Map.get(team, "id")
      # Get group from team data (old format) or derive from matches (new format)
      group = Map.get(team, "group") || Map.get(team_groups, team_id)
      # Use tla, or shortName, or first 3 chars of name as fallback for code
      code = Map.get(team, "tla") || Map.get(team, "shortName") || String.slice(Map.get(team, "name", "UNK"), 0, 3) |> String.upcase()

      if group do
        Jalka2026.Repo.insert_all(
          "teams",
          [
            %{
              id: team_id,
              name: Map.get(team, "name"),
              code: code,
              flag: Map.get(team, "crest"),
              group: group,
              inserted_at: now,
              updated_at: now
            }
          ],
          on_conflict: {:replace, [:name, :code, :flag, :group, :updated_at]},
          conflict_target: :id
        )
      else
        Logger.warning("Skipping team #{team_id} (#{Map.get(team, "name")}) - no group found")
      end
    end)

    final_count = Jalka2026.Repo.one(from t in "teams", select: count(t.id))
    Logger.info("Teams table now has #{final_count} entries")
  end

  def down do
    # No rollback - data migration
    :ok
  end
end
