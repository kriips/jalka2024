defmodule Jalka2026.Repo.Migrations.CreateGroupPredictions do
  use Ecto.Migration

  def change do
    create table(:group_prediction) do
      add :match_id, references("matches")
      add :user_id, references("users")
      add(:home_score, :integer)
      add(:away_score, :integer)
      add(:result, :string)

      timestamps()
    end

    create(index(:group_prediction, [:user_id, :match_id]))
    create(index(:group_prediction, [:user_id]))
  end
end
