defmodule Jalka2026.Repo.Migrations.CreateHistoricalMatches do
  use Ecto.Migration

  def change do
    create table(:historical_matches) do
      add(:home_team_code, :string, null: false)
      add(:away_team_code, :string, null: false)
      add(:home_team_name, :string, null: false)
      add(:away_team_name, :string, null: false)
      add(:home_score, :integer, null: false)
      add(:away_score, :integer, null: false)
      add(:date, :date, null: false)
      add(:competition, :string, null: false)
      add(:stage, :string)
      add(:venue, :string)
      add(:is_world_cup, :boolean, default: false, null: false)

      timestamps()
    end

    create(index(:historical_matches, [:home_team_code]))
    create(index(:historical_matches, [:away_team_code]))
    create(index(:historical_matches, [:competition]))
    create(index(:historical_matches, [:is_world_cup]))
    create(index(:historical_matches, [:date]))
  end
end
