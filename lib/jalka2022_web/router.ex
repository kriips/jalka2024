defmodule Jalka2022Web.Router do
  use Jalka2022Web, :router

  import Jalka2022Web.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Jalka2022Web.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Jalka2022Web do
    pipe_through :browser
    live "/", PageLive, :index
    live "/football/games/:id", FootballLive.Game, :view
    live "/football/games", FootballLive.Games, :view
    live "/football/playoffs", FootballLive.Playoffs, :view
  end

  # Other scopes may use custom stacks.
  # scope "/api", Jalka2022Web do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Application.fetch_env!(:jalka2022, :env) in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: Jalka2022Web.Telemetry
    end
  end

  ## Authentication routes

  scope "/", Jalka2022Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/users/register", UserRegistrationLive.New, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", Jalka2022Web do
    pipe_through [:browser, :require_authenticated_user]

    live "/football/predict", UserPredictionLive.Navigate, :navigate
    live "/football/predict/playoffs", UserPredictionLive.Playoffs, :edit
    live "/football/predict/:group", UserPredictionLive.Groups, :edit
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", Jalka2022Web do
    pipe_through [:browser]
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
