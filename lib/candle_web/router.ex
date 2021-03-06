defmodule CandleWeb.Router do
  use CandleWeb, :router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug CandleWeb.Plugs.PlayerSession
    plug CandleWeb.Plugs.SetLocale
    plug :fetch_live_flash
    plug :put_root_layout, {CandleWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :basic_auth,
      username: "admin",
      password: Application.fetch_env!(:candle, :admin_password)
  end

  scope "/", CandleWeb do
    pipe_through :browser

    live "/", NewGameLive, :index
    put "/player", PlayerController, :update
    live "/games/:id", GameLive, :show
    get "/about", PageController, :about
  end

  # Other scopes may use custom stacks.
  # scope "/api", CandleWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: CandleWeb.Telemetry
  end
end
