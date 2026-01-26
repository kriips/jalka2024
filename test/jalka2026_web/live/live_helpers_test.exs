defmodule Jalka2026Web.LiveHelpersTest do
  use ExUnit.Case, async: true

  alias Jalka2026Web.LiveHelpers

  describe "predictions_open?/0" do
    setup do
      # Store original deadline
      original_deadline = Application.get_env(:jalka2026, :prediction_deadline)
      on_exit(fn -> Application.put_env(:jalka2026, :prediction_deadline, original_deadline) end)
      :ok
    end

    test "returns true when deadline is in the future" do
      future_deadline = DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second)
      Application.put_env(:jalka2026, :prediction_deadline, future_deadline)

      assert LiveHelpers.predictions_open?() == true
    end

    test "returns false when deadline has passed" do
      past_deadline = DateTime.utc_now() |> DateTime.add(-24 * 60 * 60, :second)
      Application.put_env(:jalka2026, :prediction_deadline, past_deadline)

      assert LiveHelpers.predictions_open?() == false
    end

    test "returns true when deadline is nil" do
      Application.put_env(:jalka2026, :prediction_deadline, nil)

      assert LiveHelpers.predictions_open?() == true
    end

    test "returns false at exact deadline time (just passed)" do
      just_passed = DateTime.utc_now() |> DateTime.add(-1, :second)
      Application.put_env(:jalka2026, :prediction_deadline, just_passed)

      assert LiveHelpers.predictions_open?() == false
    end
  end
end
