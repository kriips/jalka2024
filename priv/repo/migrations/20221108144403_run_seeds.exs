defmodule Jalka2026.Repo.Migrations.RunSeeds do
  use Ecto.Migration

  def change do
    Jalka2026.Seed.seed()
  end
end
