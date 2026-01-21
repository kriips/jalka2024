defmodule Jalka2026Web.PageLiveTest do
  use Jalka2026Web.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    # The app shows football prediction rules - check for MM 2026 content
    assert disconnected_html =~ "MM 2026"
    assert render(page_live) =~ "MM 2026"
  end
end
