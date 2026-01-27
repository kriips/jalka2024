defmodule Jalka2026.Football.HistoricalMatch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "historical_matches" do
    field(:home_team_code, :string)
    field(:away_team_code, :string)
    field(:home_team_name, :string)
    field(:away_team_name, :string)
    field(:home_score, :integer)
    field(:away_score, :integer)
    field(:date, :date)
    field(:competition, :string)
    field(:stage, :string)
    field(:venue, :string)
    field(:is_world_cup, :boolean, default: false)

    timestamps()
  end

  @doc false
  def changeset(historical_match, attrs) do
    historical_match
    |> cast(attrs, [
      :home_team_code,
      :away_team_code,
      :home_team_name,
      :away_team_name,
      :home_score,
      :away_score,
      :date,
      :competition,
      :stage,
      :venue,
      :is_world_cup
    ])
    |> validate_required([
      :home_team_code,
      :away_team_code,
      :home_team_name,
      :away_team_name,
      :home_score,
      :away_score,
      :date,
      :competition
    ])
  end
end
