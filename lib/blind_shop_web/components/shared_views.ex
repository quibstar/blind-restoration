defmodule SharedViews do
  @moduledoc """
  A component for rendering social media links in the layout.
  This component provides links to Facebook, Instagram, and Twitter.
  It can be used in the layout templates to provide easy access to social media profiles.
  """

  import BlindShopWeb.Layouts

  use BlindShopWeb, :html

  def header(assigns) do
    ~H"""
    <header
      class="border-b border-base-300 shadow-sm px-4 pb-4 bg-base-100"
      data-logged-in={if @current_scope, do: "true", else: "false"}
    >
      <nav class="flex items-center justify-between max-w-7xl mx-auto">
        <.link
          navigate={if @current_scope, do: "/dashboard", else: "/"}
          class="text-xl font-bold logo-color flex items-center"
        >
          <img
            src={~p"/images/logo.webp"}
            alt="Logo"
            class="inline-block h-12 w-auto ml-2 rounded-lg"
          /> BlindRestoration.com
        </.link>
        <ul class="relative z-10 hidden md:flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
          <%= if @current_scope && Map.has_key?(@current_scope, :user) && @current_scope.user do %>
            <.link
              navigate={~p"/dashboard"}
              class="text-yellow-500 hover:underline hover:text-yellow-600"
            >
              Dashboard
            </.link>
            <.dropdown id="user-menu">
              <:trigger>
                <div class="relative">
                  <button class="flex items-center gap-2 cursor-pointer">
                    <div class="avatar avatar-placeholder">
                      <div class="bg-primary text-white w-8 rounded-full">
                        <span class="text-xs">
                          {String.first(@current_scope.user.first_name)}{String.first(
                            @current_scope.user.last_name
                          )}
                        </span>
                      </div>
                    </div>
                    <.icon name="hero-chevron-down" class="h-4 w-4" />
                  </button>
                </div>
              </:trigger>

              <:content>
                <.link navigate={~p"/users/settings"} class="drop-down-nav">
                  <.icon name="hero-cog-8-tooth" class="h-4 w-4 inline-block" /> Account Settings
                </.link>

                <hr class="my-1 border-base-300" />

                <.link href={~p"/users/log-out"} method="delete" class="drop-down-nav">
                  <.icon name="hero-arrow-right-start-on-rectangle" class="h-4 w-4 inline-block" />
                  Log out
                </.link>
              </:content>
            </.dropdown>
          <% end %>
          <%= if @current_scope && Map.has_key?(@current_scope, :admin) && @current_scope.admin do %>
            <li><.link navigate={~p"/admin/dashboard"} class="btn btn-ghost">Dashboard</.link></li>
            <li><.link navigate={~p"/admin/orders"} class="btn btn-ghost">Orders</.link></li>
            <li><.link navigate={~p"/admin/customers"} class="btn btn-ghost">Customers</.link></li>
            <li><.link navigate={~p"/admin/contact-inquiries"} class="btn btn-ghost">Contact Inquiries</.link></li>
            <li><.link navigate={~p"/admin/reports"} class="btn btn-ghost">Reports</.link></li>

            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                <.icon name="hero-user" class="w-4 h-4" />
              </div>
              <ul
                tabindex="0"
                class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-52 p-2 shadow"
              >
                <li>
                  <div class="flex flex-col items-start">
                    <span class="font-semibold">{@current_scope.admin.email}</span>
                    <span class="text-xs text-base-content/70">Administrator</span>
                  </div>
                </li>
                <div class="divider my-2"></div>
                <li><.link navigate={~p"/admins/settings"}>Settings</.link></li>
                <li>
                  <.link href={~p"/admins/log-out"} method="delete" class="text-error">
                    Log out
                  </.link>
                </li>
              </ul>
            </div>
          <% end %>
          <%= if !@current_scope do %>
            <li>
              <.link href={~p"/users/log-in"} class="nav-link">
                Log in
              </.link>
            </li>

            <li>
              <.link
                href={~p"/users/register"}
                class="btn btn-primary text-primary-content hover:bg-primary-focus"
              >
                Create an account
              </.link>
            </li>
          <% end %>
        </ul>
        <div class="md:hidden flex items-center justify-between gap-2 px-4 sm:px-6 lg:px-8">
          <button
            phx-click={show("#mobile-menu")}
            type="button"
            class="relative inline-flex items-center justify-center rounded-md p-2 text-base-content focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary"
            aria-controls="mobile-menu"
            aria-expanded="false"
            aria-label={gettext("Show mobile menu")}
          >
            <span class="absolute -inset-0.5"></span>
            <span class="sr-only">Open main menu</span>
            <.icon name="hero-bars-3" class="h-6 w-6" />
          </button>
        </div>
        
    <!-- Mobile menu, show/hide based on menu state. -->
        <div
          id="mobile-menu"
          class="absolute z-50 top-0 inset-x-0 p-2 transition transform origin-top-right hidden"
        >
          <div class="rounded-lg shadow-lg divide-y-2 divide-base-200 bg-base-100 ring-1 ring-base-300">
            <div class="pt-5 pb-6 px-4">
              <div class="flex items-center justify-between -ml-4">
                <.link navigate="/" class="text-xl font-bold logo-color flex items-center">
                  <img
                    src={~p"/images/logo.webp"}
                    alt="Logo"
                    class="inline-block h-12 w-auto ml-2 rounded-lg"
                  /> BlindRestoration.com
                </.link>
                <div class="-mr-2">
                  <button
                    type="button"
                    class="rounded-md p-2 inline-flex items-center justify-center text-base-content focus:ring-primary"
                    phx-click={hide("#mobile-menu")}
                    role="button"
                  >
                    <span class="sr-only">Close menu</span>
                    <.icon name="hero-x-mark" class="h-6 w-6" />
                  </button>
                </div>
              </div>

              <div class="mt-6">
                <nav class="grid grid-cols-1 gap-2">
                  <%= if @current_scope && Map.has_key?(@current_scope, :user) do %>
                    <.link href="/users/log-out" method="delete" class="nav-link">
                      <.icon name="hero-arrow-right-start-on-rectangle" class="h-5 w-5" /> {gettext(
                        "Sign Out"
                      )}
                    </.link>

                    <.link navigate="/users/settings" class="nav-link">
                      <.icon name="hero-cog" class="h-5 w-5" /> {gettext("Account Settings")}
                    </.link>
                  <% end %>

                  <%= if !@current_scope do %>
                    <div class="mt-4">
                      <.link
                        navigate="/users/register"
                        class="w-full flex items-center justify-center btn btn-primary mb-2"
                      >
                        {gettext("Start Free")}
                      </.link>

                      <p class="text-center text-base font-medium text-base-content/70">
                        Have an account?
                        <.link
                          navigate="/users/log-in"
                          class="underline text-base-content/70 hover:text-base-content"
                        >
                          {gettext("Sign In")}
                        </.link>
                      </p>
                    </div>
                  <% end %>
                </nav>
              </div>
            </div>
          </div>
        </div>
      </nav>
    </header>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer class="text-center text-sm text-base-content/60 py-4 border-t border-base-300 bg-base-100">
      <div class="max-w-7xl mx-auto md:flex justify-between items-center p-4 space-y-4 md:space-y-0">
        <p>© {DateTime.utc_now().year} BlindRestoration.com. All rights reserved.</p>
        <div class="">
          <.link navigate="/about" class="footer-link">
            {gettext("About")}
          </.link>

          <.link navigate="/terms-of-service" class="footer-link">
            {gettext("Terms")}
          </.link>

          <.link navigate="/privacy-policy" class="footer-link">
            {gettext("Privacy")}
          </.link>

          <.link navigate="/contact" class="footer-link">
            {gettext("Contact")}
          </.link>

          <.link navigate="/faq" class="footer-link">
            {gettext("FAQ")}
          </.link>
        </div>
        <SharedViews.social_links />
      </div>
    </footer>
    """
  end

  def social_links(assigns) do
    ~H"""
    <div class="flex justify-center space-x-1 md:space-x-6 md:order-3 text-base-content/60 hover:text-base-content">
      <a
        href="https://www.facebook.com/BlindRestoration.com"
        _target="blank"
        class="p-3 md:p-0 hover:text-primary transition-colors flex items-center"
      >
        <span class="sr-only">Facebook</span>
        <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill-rule="evenodd"
            d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"
            clip-rule="evenodd"
          />
        </svg>
      </a>
      <a
        href="https://www.instagram.com/BlindRestoration.com/"
        _target="blank"
        class="p-3 md:p-0 hover:text-primary transition-colors flex items-center"
      >
        <span class="sr-only">Instagram</span>
        <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill-rule="evenodd"
            d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z"
            clip-rule="evenodd"
          />
        </svg>
      </a>

      <a
        href="https://twitter.com/BlindRestoration.com"
        _target="blank"
        class="p-3 md:p-0 hover:text-primary transition-colors flex items-center"
      >
        <span class="sr-only">Twitter</span>
        <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
        </svg>
      </a>
      <div>
        <div class="flex justify-center">
          <.theme_toggle />
        </div>
      </div>
    </div>
    """
  end
end
