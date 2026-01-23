defmodule Jalka2026Web.ErrorHTMLTest do
  use Jalka2026Web.ConnCase, async: true

  test "renders 404.html" do
    assert Jalka2026Web.ErrorHTML.render("404.html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert Jalka2026Web.ErrorHTML.render("500.html", []) == "Internal Server Error"
  end
end
