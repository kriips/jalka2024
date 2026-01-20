defmodule Jalka2026Web.UserRegistrationLive.New do
  use Phoenix.LiveView

  alias Jalka2026.Accounts
  alias Jalka2026.Accounts.User
  alias Jalka2026Web.Resolvers.AccountsResolver

  defp search(query) do
    AccountsResolver.list_allowed_users(query)
    |> Enum.map(fn user ->
      {user.id, user.name}
    end)
    |> Enum.slice(0, 10)
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    {:ok, assign(socket, changeset: changeset, query: "", results: %{}, trigger_submit: false)}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2026Web.UserRegistrationView, "new.html", assigns)

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    require Logger
    Logger.info("validate event incoming")

    changeset =
      %User{}
      |> Jalka2026.Accounts.change_user_registration(user_params)
      |> Map.put(:action, :insert)

    results = search(user_params["name"])

    Logger.info(results)

    {:noreply,
     assign(socket,
       results: results,
       query: user_params["name"],
       changeset: changeset
     )}
  end

  def handle_event("save", %{"user" => _user_params}, socket) do
    {:noreply, socket |> assign(trigger_submit: socket.assigns.changeset.valid?)}
  end
end
