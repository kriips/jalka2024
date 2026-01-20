defmodule Jalka2026.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add(:group, :string, null: false)
      add :home_team_id, references("teams")
      add :away_team_id, references("teams")
      add(:home_score, :integer)
      add(:away_score, :integer)
      add(:result, :string)
      add(:date, :naive_datetime)
      add(:finished, :boolean, null: false)

      timestamps()
    end

    create(index(:matches, [:id]))
    create(index(:matches, [:group]))
  end
end
