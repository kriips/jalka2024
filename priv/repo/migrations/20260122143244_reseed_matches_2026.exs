defmodule Jalka2026.Repo.Migrations.ReseedMatches2026 do
  use Ecto.Migration
  require Logger

  def up do
    # Get prefix for file paths
    prefix = case Application.get_env(:jalka2026, :environment) do
      :prod -> "/app/lib/jalka2026-0.1.0"
      _ -> Mix.Project.app_path()
    end

    # Load matches from JSON
    matches_file = ~c"#{prefix}/priv/repo/data/matches.json"
    matches_data = Jason.decode!(File.read!(matches_file))
    matches = if is_list(matches_data), do: matches_data, else: Map.get(matches_data, "matches", [])

    # Filter to only GROUP_STAGE matches with valid teams
    group_matches = matches
    |> Enum.filter(fn match ->
      match["stage"] == "GROUP_STAGE" &&
      !is_nil(Kernel.get_in(match, ["homeTeam", "id"])) &&
      !is_nil(Kernel.get_in(match, ["awayTeam", "id"]))
    end)

    Logger.info("Reseeding matches with #{length(group_matches)} group stage matches for 2026 tournament...")

    # Delete existing group predictions that reference old matches
    execute("DELETE FROM group_prediction")

    # Delete all existing matches
    execute("DELETE FROM matches")

    # Insert all matches from the JSON file using raw SQL
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    now_str = NaiveDateTime.to_string(now)

    Enum.each(group_matches, fn match ->
      # Transform GROUP_A -> Alagrupp A, GROUP_B -> Alagrupp B, etc.
      group_letter = match["group"] |> String.replace("GROUP_", "")
      group = "Alagrupp #{group_letter}"

      # Parse the UTC date string
      date_str = case NaiveDateTime.from_iso8601(match["utcDate"]) do
        {:ok, naive_dt} -> "'#{NaiveDateTime.to_string(naive_dt)}'"
        _ -> "NULL"
      end

      match_id = match["id"]
      home_team_id = Kernel.get_in(match, ["homeTeam", "id"])
      away_team_id = Kernel.get_in(match, ["awayTeam", "id"])

      # Escape single quotes in group name
      escaped_group = String.replace(group, "'", "''")

      execute("""
      INSERT INTO matches (id, "group", home_team_id, away_team_id, home_score, away_score, result, date, finished, inserted_at, updated_at)
      VALUES (#{match_id}, '#{escaped_group}', #{home_team_id}, #{away_team_id}, NULL, NULL, NULL, #{date_str}, false, '#{now_str}', '#{now_str}')
      ON CONFLICT (id) DO UPDATE SET
        "group" = EXCLUDED."group",
        home_team_id = EXCLUDED.home_team_id,
        away_team_id = EXCLUDED.away_team_id,
        date = EXCLUDED.date,
        updated_at = EXCLUDED.updated_at
      """)
    end)

    Logger.info("Inserted #{length(group_matches)} matches")
  end

  def down do
    # No rollback - data migration
    :ok
  end
end
