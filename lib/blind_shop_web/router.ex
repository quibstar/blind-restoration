defmodule BlindShopWeb.Router do
  use BlindShopWeb, :router

  import BlindShopWeb.AdminAuth

  import BlindShopWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlindShopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :user_browser do
    plug :browser
    plug :fetch_current_scope_for_user
  end

  pipeline :admin_browser do
    plug :browser
    plug :fetch_current_scope_for_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :stripe_webhook do
    plug :accepts, ["json"]
    plug BlindShopWeb.Plugs.RawBody
  end

  scope "/", BlindShopWeb do
    pipe_through :user_browser

    get "/", PageController, :home
    get "/shipping-instructions", PageController, :shipping_instructions
    get "/terms-of-service", PageController, :terms_of_service
    get "/privacy-policy", PageController, :privacy_policy
    get "/sitemap.xml", SitemapController, :index
  end

  # Stripe webhook endpoint (no authentication needed)
  scope "/webhooks", BlindShopWeb do
    pipe_through :stripe_webhook
    
    post "/stripe", StripeWebhookController, :handle
  end
  
  # Other scopes may use custom stacks.
  # scope "/api", BlindShopWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:blind_shop, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :user_browser

      live_dashboard "/dashboard", metrics: BlindShopWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## User Authentication routes

  scope "/", BlindShopWeb do
    pipe_through [:user_browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{BlindShopWeb.UserAuth, :require_authenticated}] do
      live "/dashboard", DashboardLive, :index
      live "/orders", OrderLive.Index, :index
      live "/orders/new", OrderLive.Form, :new
      live "/orders/invoice-paid", OrderLive.InvoicePaid, :show
      live "/orders/:id", OrderLive.Show, :show
      live "/orders/:id/edit", OrderLive.Form, :edit
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", BlindShopWeb do
    pipe_through [:user_browser]

    # Payment success/cancel routes (accessible without authentication)
    get "/orders/success", PaymentController, :success
    get "/orders/cancel", PaymentController, :cancel

    live_session :current_user,
      on_mount: [{BlindShopWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Admin Authentication routes

  scope "/", BlindShopWeb do
    pipe_through [:admin_browser, :require_authenticated_admin]

    live_session :require_authenticated_admin,
      on_mount: [{BlindShopWeb.AdminAuth, :require_authenticated}] do
      live "/admin/dashboard", AdminLive.Dashboard, :index
      live "/admin/orders", AdminLive.Orders, :index
      live "/admin/orders/:id/invoice", AdminLive.InvoiceForm, :new
      live "/admin/orders/:id", AdminLive.OrderDetail, :show
      live "/admin/customers", AdminLive.Customers, :index
      live "/admin/reports", AdminLive.Reports, :index
      live "/admins/settings", AdminLive.Settings, :edit
      live "/admins/settings/confirm-email/:token", AdminLive.Settings, :confirm_email
    end

    post "/admins/update-password", AdminSessionController, :update_password
  end

  scope "/", BlindShopWeb do
    pipe_through [:admin_browser]

    live_session :current_admin,
      on_mount: [{BlindShopWeb.AdminAuth, :mount_current_scope}] do
      live "/admins/register", AdminLive.Registration, :new
      live "/admins/log-in", AdminLive.Login, :new
      live "/admins/log-in/:token", AdminLive.Confirmation, :new
    end

    post "/admins/log-in", AdminSessionController, :create
    delete "/admins/log-out", AdminSessionController, :delete
  end
end
