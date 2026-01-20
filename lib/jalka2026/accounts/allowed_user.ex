defmodule Jalka2026.Accounts.AllowedUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "allowed_users" do
    field(:name, :string)
    timestamps()
  end

  @doc false
  def changeset(allowed_user, attrs) do
    allowed_user
    |> cast(attrs, [:name])
    |> unique_constraint(:name)
  end
end
