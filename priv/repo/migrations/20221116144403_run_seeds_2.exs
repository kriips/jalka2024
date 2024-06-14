defmodule Jalka2024.Repo.Migrations.RunSeeds do
  use Ecto.Migration

  def change do
    Jalka2024.Seed.seed2()
  end
end
