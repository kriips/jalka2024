defmodule Jalka2026.Seed do
  require Logger
  def seed do
    prefix = case Application.get_env(:jalka2026, :environment) do
      :prod -> "/app/lib/jalka2026-0.1.0"
      _ -> Mix.Project.app_path()
    end
    if Code.ensure_compiled(Jalka2026.Accounts.AllowedUser) &&
         Jalka2026.Accounts.AllowedUser |> Jalka2026.Repo.aggregate(:count, :id) == 0 do
      Enum.each(
        Jason.decode!(File.read!("#{prefix}/priv/repo/data/allowed_users.json")),
        fn attrs ->
          %Jalka2026.Accounts.AllowedUser{}
          |> Jalka2026.Accounts.AllowedUser.changeset(attrs)
          |> Jalka2026.Repo.insert!()
        end
      )
    end

    # Load matches first to derive team groups (new format doesn't have group in teams.json)
    matches_data = Jason.decode!(File.read!("#{prefix}/priv/repo/data/matches.json"))
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

    if Code.ensure_compiled(Jalka2026.Football.Team) &&
         Jalka2026.Football.Team |> Jalka2026.Repo.aggregate(:count, :id) == 0 do
      teams_data = Jason.decode!(File.read!("#{prefix}/priv/repo/data/teams.json"))
      # Handle both old format (flat array) and new format (object with "teams" key)
      teams = if is_list(teams_data), do: teams_data, else: Map.get(teams_data, "teams", [])

      Enum.each(
        teams,
        fn attrs ->
          team_id = Map.get(attrs, "id")
          # Get group from team data (old format) or derive from matches (new format)
          group = Map.get(attrs, "group") || Map.get(team_groups, team_id)
          # Use tla, or shortName, or first 3 chars of name as fallback for code
          code = Map.get(attrs, "tla") || Map.get(attrs, "shortName") || String.slice(Map.get(attrs, "name", "UNK"), 0, 3) |> String.upcase()

          if group do
            %Jalka2026.Football.Team{}
            |> Jalka2026.Football.Team.changeset(%{
              id: team_id,
              name: Map.get(attrs, "name"),
              code: code,
              flag: Map.get(attrs, "crest"),
              group: group
            })
            |> Jalka2026.Repo.insert!()
          else
            Logger.warning("Skipping team #{team_id} (#{Map.get(attrs, "name")}) - no group found")
          end
        end
      )
    end

    if Code.ensure_compiled(Jalka2026.Football.Match) &&
         Jalka2026.Football.Match |> Jalka2026.Repo.aggregate(:count, :id) == 0 do
      Enum.each(
        matches,
        fn attrs ->
          home_team_id = Kernel.get_in(attrs, ["homeTeam", "id"])
          away_team_id = Kernel.get_in(attrs, ["awayTeam", "id"])

          if Map.get(attrs, "stage") == "GROUP_STAGE" && home_team_id && away_team_id do
            # Transform GROUP_A -> Alagrupp A, GROUP_B -> Alagrupp B, etc.
            group_letter = Map.get(attrs, "group") |> String.replace("GROUP_", "")
            group = "Alagrupp #{group_letter}"

            %Jalka2026.Football.Match{}
            |> Jalka2026.Football.Match.changeset(%{
              group: group,
              home_team_id: home_team_id,
              away_team_id: away_team_id,
              date: Map.get(attrs, "utcDate")
            })
            |> Jalka2026.Repo.insert!()
          end
        end
      )
    end
  end

  def seed2 do
    prefix = case Application.get_env(:jalka2026, :environment) do
      :prod -> "/app/lib/jalka2026-0.1.0"
      _ -> Mix.Project.app_path()
    end

    # For 2026 tournament: Load any additional users from allowed_users2.json
    # The main allowed_users.json now has 990 users for the 2026 tournament
    if Code.ensure_compiled(Jalka2026.Accounts.AllowedUser) do
      current_count = Jalka2026.Accounts.AllowedUser |> Jalka2026.Repo.aggregate(:count, :id)

      # Only add secondary users if count is below expected 990 (2026 tournament list)
      if current_count < 990 do
        Logger.info("Adding secondary seed data for 2026 tournament...")
        secondary_file = "#{prefix}/priv/repo/data/allowed_users2.json"

        if File.exists?(secondary_file) do
          Enum.each(
            Jason.decode!(File.read!(secondary_file)),
            fn attrs ->
              # Use insert with on_conflict to handle duplicates gracefully
              %Jalka2026.Accounts.AllowedUser{}
              |> Jalka2026.Accounts.AllowedUser.changeset(attrs)
              |> Jalka2026.Repo.insert(on_conflict: :nothing)
            end
          )
        end
      end
    end
  end
end
