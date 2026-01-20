defmodule Jalka2026.Repo.Migrations.CreateAllowedUsers do
  use Ecto.Migration

  def change do
    create table(:allowed_users) do
      add(:name, :string, null: false)

      timestamps()
    end

    create(index(:allowed_users, [:id]))
    create(index(:allowed_users, [:name]))
  end
end
