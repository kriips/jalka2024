defmodule Jalka2026Web.FootballLive.GroupScenarios do
  use Jalka2026Web, :live_view

  alias Jalka2026.Football.GroupScenarios

  @impl true
  def mount(params, _session, socket) do
    group = Map.get(params, "group", "A")

    # Validate group
    group =
      if group in GroupScenarios.valid_groups() do
        group
      else
        "A"
      end

    scenario_data = GroupScenarios.calculate_scenarios(group)
    team_requirements = GroupScenarios.analyze_team_requirements(group)

    {:ok,
     assign(socket,
       group: group,
       scenario_data: scenario_data,
       team_requirements: team_requirements,
       selected_scenario: nil
     )}
  end

  @impl true
  def handle_params(%{"group" => group}, _uri, socket) do
    group =
      if group in GroupScenarios.valid_groups() do
        group
      else
        "A"
      end

    scenario_data = GroupScenarios.calculate_scenarios(group)
    team_requirements = GroupScenarios.analyze_team_requirements(group)

    {:noreply,
     assign(socket,
       group: group,
       scenario_data: scenario_data,
       team_requirements: team_requirements,
       selected_scenario: nil
     )}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("select_scenario", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    scenarios = socket.assigns.scenario_data.scenarios

    selected =
      if index >= 0 and index < length(scenarios) do
        Enum.at(scenarios, index)
      else
        nil
      end

    {:noreply, assign(socket, selected_scenario: selected)}
  end

  def handle_event("clear_scenario", _params, socket) do
    {:noreply, assign(socket, selected_scenario: nil)}
  end

  # Helper functions for template
  def status_class(:qualified), do: "status-qualified"
  def status_class(:eliminated), do: "status-eliminated"
  def status_class(:likely), do: "status-likely"
  def status_class(:possible), do: "status-possible"
  def status_class(:unlikely), do: "status-unlikely"
  def status_class(_), do: ""

  def status_label(:qualified), do: "Kindlalt edasi"
  def status_label(:eliminated), do: "Langenud"
  def status_label(:likely), do: "Tõenäoline"
  def status_label(:possible), do: "Võimalik"
  def status_label(:unlikely), do: "Ebatõenäoline"
  def status_label(_), do: "Teadmata"

  def outcome_label(:home_win), do: "1"
  def outcome_label(:draw), do: "X"
  def outcome_label(:away_win), do: "2"

  def format_goal_diff(gd) when gd > 0, do: "+#{gd}"
  def format_goal_diff(gd), do: "#{gd}"

  def rank_class(1), do: "gold"
  def rank_class(2), do: "silver"
  def rank_class(3), do: "bronze"
  def rank_class(_), do: "default"

  def prev_group(group) do
    groups = GroupScenarios.valid_groups()
    index = Enum.find_index(groups, &(&1 == group))

    if index && index > 0 do
      Enum.at(groups, index - 1)
    else
      nil
    end
  end

  def next_group(group) do
    groups = GroupScenarios.valid_groups()
    index = Enum.find_index(groups, &(&1 == group))

    if index && index < length(groups) - 1 do
      Enum.at(groups, index + 1)
    else
      nil
    end
  end
end
