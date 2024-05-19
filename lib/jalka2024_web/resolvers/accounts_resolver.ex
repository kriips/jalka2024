defmodule Jalka2024Web.Resolvers.AccountsResolver do
  alias Jalka2024.{Accounts, Repo}
  alias Accounts.{User}

  def list_users() do
    User
    |> Repo.all()
  end

  def list_allowed_users(query) do
    require Logger
    Logger.debug("list_allowed_user" <> query)
    Jalka2024.Accounts.get_allowed_users_by_name(query)
  end

  def find_user(_parent, %{id: id}, _resolution) do
    case Jalka2024.Accounts.get_user!(id) do
      nil ->
        {:error, "User ID #{id} not found"}

      user ->
        {:ok, user}
    end
  end

  def get_user(user_id) do
    Jalka2024.Accounts.get_user!(user_id)
  end

  def current_user(_, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end

  def current_user(_, _) do
    {:ok, nil}
  end
end
