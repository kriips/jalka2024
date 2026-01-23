defmodule Jalka2026Web.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.Component
  alias Jalka2026.Accounts
  alias Jalka2026.Accounts.User
  alias Jalka2026Web.Router.Helpers, as: Routes

  def assign_defaults(session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        find_current_user(session)
      end)

    case socket.assigns.current_user do
      %User{} ->
        socket

      _other ->
        socket
        |> put_flash(:error, "Selle lehe nägemiseks pead sisse logima")
        |> redirect(to: Routes.user_session_path(socket, :new))
    end
  end

  @doc """
  Checks if predictions are still open (before the tournament deadline).
  Returns true if predictions can still be made, false if the deadline has passed.
  """
  def predictions_open? do
    deadline = Application.get_env(:jalka2026, :prediction_deadline)
    deadline == nil or DateTime.compare(DateTime.utc_now(), deadline) == :lt
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end
end
