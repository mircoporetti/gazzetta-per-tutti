defmodule GazzettaPerTuttiWeb.Router do
  use GazzettaPerTuttiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GazzettaPerTuttiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GazzettaPerTuttiWeb do
    get "/health", HealthController, :show
  end

  scope "/", GazzettaPerTuttiWeb do
    pipe_through :browser

    live "/", ActsLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", GazzettaPerTuttiWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:gazzetta_per_tutti, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GazzettaPerTuttiWeb.Telemetry
    end
  end
end
