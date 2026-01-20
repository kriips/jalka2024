defmodule Jalka2026.Accounts.UserNotifier do
  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, body) do
    require Logger
    Logger.debug(body)
    {:ok, %{to: to, body: body}}
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, """

    ==============================

    Tere #{user.email},

    oma konto kinnitamiseks vajuta allolevale lingile:

    #{url}

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, """

    ==============================

    Tere #{user.email},

    parooli lähtestamiseks mine allolevale lingile:

    #{url}

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, """

    ==============================

    Tere #{user.email},

    oma meiliaadressi vahetamiseks mine allolevale lingile:

    #{url}

    ==============================
    """)
  end
end
