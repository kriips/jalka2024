defmodule Jalka2026.Repo.Migrations.CreatePoPredictions do
  use Ecto.Migration

  def change do
    create table(:playoff_predictions) do
      add :phase, :integer
      add :user_id, references("users")
      add :team_id, references("teams")

      timestamps()
    end
  end
end
