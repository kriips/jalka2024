defmodule Jalka2026Web.UserPredictionLive.Groups do
  use Jalka2026Web, :live_view

  alias Jalka2026Web.Resolvers.FootballResolver
  alias Jalka2026.Football.{Match}

  @impl true
  def mount(params, session, socket) do
    group = Map.get(params, "group")
    socket = Jalka2026Web.LiveHelpers.assign_defaults(session, socket)

    predictions =
      FootballResolver.list_matches_by_group(group)
      |> Enum.map(fn match -> add_score(match, socket) end)

    {:ok,
     assign(socket,
       group: group,
       predictions: predictions,
       predictions_done: predictions_done_count(predictions)
     )}
  end

  @impl true
  def handle_event("inc-score", user_params, socket) do
    if Jalka2026Web.LiveHelpers.predictions_open?() do
      changed_score =
        case user_params["side"] do
          "home" ->
            {inc_score(user_params["home-score"]), nullify_hyphen(user_params["away-score"])}

          "away" ->
            {nullify_hyphen(user_params["home-score"]), inc_score(user_params["away-score"])}
        end

      match_id = String.to_integer(user_params["match"])

      updated_prediction =
        FootballResolver.change_prediction_score(%{
          match_id: match_id,
          user_id: socket.assigns.current_user.id,
          side: user_params["side"],
          score: changed_score
        })

      {:noreply, socket |> update_prediction(match_id, updated_prediction)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Ennustamine on suletud - turniir on alanud")
       |> redirect(to: "/")}
    end
  end

  def handle_event("dec-score", user_params, socket) do
    if Jalka2026Web.LiveHelpers.predictions_open?() do
      changed_score =
        case user_params["side"] do
          "home" ->
            {dec_score(user_params["home-score"]), nullify_hyphen(user_params["away-score"])}

          "away" ->
            {nullify_hyphen(user_params["home-score"]), dec_score(user_params["away-score"])}
        end

      match_id = String.to_integer(user_params["match"])

      updated_prediction =
        FootballResolver.change_prediction_score(%{
          match_id: match_id,
          user_id: socket.assigns.current_user.id,
          side: user_params["side"],
          score: changed_score
        })

      {:noreply, socket |> update_prediction(match_id, updated_prediction)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Ennustamine on suletud - turniir on alanud")
       |> redirect(to: "/")}
    end
  end

  defp add_score(%Match{} = match, socket) do
    scores =
      case FootballResolver.get_prediction(%{
             match_id: match.id,
             user_id: socket.assigns.current_user.id
           }) do
        %{home_score: home_score, away_score: away_score} -> {home_score, away_score}
        _ -> {"-", "-"}
      end

    {match, scores}
  end

  defp inc_score(score) do
    case score do
      "-" -> 1
      x -> String.to_integer(x) + 1
    end
  end

  defp dec_score(score) do
    case score do
      "-" -> 0
      "0" -> 0
      x -> String.to_integer(x) - 1
    end
  end

  defp nullify_hyphen(score) do
    case score do
      "-" -> 0
      x -> String.to_integer(x)
    end
  end

  defp update_prediction(socket, match_id, updated_prediction) do
    predictions =
      socket.assigns.predictions
      |> Enum.map(fn {match, _score} = prediction ->
        if match.id == match_id do
          {match, {updated_prediction.home_score, updated_prediction.away_score}}
        else
          prediction
        end
      end)

    socket
    |> assign(predictions: predictions, predictions_done: predictions_done_count(predictions))
  end

  defp predictions_done_count(predictions) do
    case Enum.count(predictions, fn {_pred, {home_score, away_score}} ->
           away_score != "-" or home_score != "-"
         end) < 6 do
      true -> "button-outline"
      _ -> ""
    end
  end
end
