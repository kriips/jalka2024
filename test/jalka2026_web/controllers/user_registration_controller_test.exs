defmodule Jalka2026Web.UserRegistrationControllerTest do
  use Jalka2026Web.ConnCase, async: true

  import Jalka2026.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_new_path(conn, :new))
      response = html_response(conn, 200)
      # App uses Estonian - "Registreeri" means "Register"
      assert response =~ "Registreeri</h1>"
      assert response =~ "Sisene</a>"
      assert response =~ "Registreeri</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn =
        conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_new_path(conn, :new))

      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      name = unique_user_name()
      # First create the allowed user entry (whitelist)
      allowed_user_fixture(%{name: name})

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => valid_user_attributes(name: name)
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/football/predict"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ name
      # App uses Estonian - "Välju" means "Log out"
      assert response =~ "Välju</a>"
    end

    test "redirects on invalid data", %{conn: conn} do
      # Registration with invalid data redirects to login page
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"name" => "NotInWhitelist", "password" => "too short"}
        })

      # The controller redirects to session path on error
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
