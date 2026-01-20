defmodule Jalka2026.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add(:name, :string, null: false)
      add(:flag, :string, null: false)
      add(:code, :string, null: false)
      add(:group, :string, null: false)
      timestamps()
    end

    create(index(:teams, [:id]))
  end
end
