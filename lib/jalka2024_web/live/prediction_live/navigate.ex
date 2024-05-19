defmodule Jalka2024Web.UserPredictionLive.Navigate do
  use Phoenix.LiveView

  alias Jalka2024Web.Resolvers.FootballResolver
  alias Jalka2024Web.LiveHelpers

  @impl true
  def mount(_params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)
    filled_predictions = FootballResolver.filled_predictions(socket.assigns.current_user.id)
    playoff_predictions = FootballResolver.get_playoff_predictions(socket.assigns.current_user.id)
    progress = count_progress(filled_predictions, playoff_predictions)
    progress_percentage = progress_percentage(progress)

    playoffs_disabled =
      case progress < 36 do
        true -> "disabled"
        _ -> ""
      end

    playoffs_filled =
      case progress == 67 do
        true -> ""
        _ -> "button-outline"
      end

    {:ok,
     assign(socket,
       filled: map_style(filled_predictions),
       progress: progress_percentage,
       playoffs_disabled: playoffs_disabled,
       playoffs_filled: playoffs_filled
     )}
  end

  @impl true
  def render(assigns),
    do: Phoenix.View.render(Jalka2024Web.PredictionView, "navigate.html", assigns)

  defp map_style(filled_predictions) do
    filled_predictions
    |> Enum.map(fn {group, count} ->
      if count != 6 do
        {group, "button-outline"}
      else
        {group, ""}
      end
    end)
    |> Enum.into(%{})
  end

  defp count_progress(filled_predictions, playoff_predictions) do
    group_count =
      filled_predictions
      |> Enum.reduce(0, fn {_group, count}, acc ->
        acc + count
      end)

    playoff_count =
      playoff_predictions
      |> Enum.map(fn {_phase, teams} -> teams end)
      |> List.flatten()
      |> Enum.count()

    group_count + playoff_count
  end

  defp progress_percentage(progress) do
    progress * 100 / 67
  end
end
