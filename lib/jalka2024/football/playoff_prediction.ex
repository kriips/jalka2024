defmodule Jalka2024.Football.PlayoffPrediction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Jalka2024.Football.Team
  alias Jalka2024.Repo
  alias Jalka2024.Accounts.User

  schema "playoff_predictions" do
    belongs_to(:user, User)
    belongs_to(:team, Team)
    field(:phase, :integer)

    timestamps()
  end

  @doc false
  def changeset(playoff_prediction, attrs) do
    playoff_prediction
    |> cast(attrs, [:user_id, :team_id, :phase])
  end

  def get_playoff_prediction!(id) do
    Repo.get!(PlayoffPrediction, id)
  end

  @doc false
  def create_changeset(playoff_prediction, attrs) do
    playoff_prediction
    |> cast(attrs, [:user_id, :team_id, :phase])
    |> cast_assoc(:user)
    |> assoc_constraint(:user)
    |> cast_assoc(:team)
    |> assoc_constraint(:team)
  end
end
