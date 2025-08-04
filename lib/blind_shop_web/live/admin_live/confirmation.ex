defmodule BlindShopWeb.AdminLive.Confirmation do
  use BlindShopWeb, :live_view

  alias BlindShop.Admins

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm my-12 bg-base-100 p-4 rounded shadow">
        <div class="text-center">
          <.header>Welcome {@admin.email}</.header>
        </div>

        <.form
          :if={!@admin.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/admins/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            class="btn btn-primary w-full"
          >
            Confirm and stay logged in
          </.button>
          <.button phx-disable-with="Confirming..." class="btn btn-primary btn-soft w-full mt-2">
            Confirm and log in only this time
          </.button>
        </.form>

        <.form
          :if={@admin.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/admins/log-in"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope do %>
            <.button phx-disable-with="Logging in..." class="btn btn-primary w-full">
              Log in
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Logging in..."
              class="btn btn-primary w-full"
            >
              Keep me logged in on this device
            </.button>
            <.button phx-disable-with="Logging in..." class="btn btn-primary btn-soft w-full mt-2">
              Log me in only this time
            </.button>
          <% end %>
        </.form>

        <p :if={!@admin.confirmed_at} class="alert alert-outline mt-8">
          Tip: If you prefer passwords, you can enable them in the admin settings.
        </p>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    if admin = Admins.get_admin_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "admin")

      {:ok, assign(socket, admin: admin, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/admins/log-in")}
    end
  end

  def handle_event("submit", %{"admin" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "admin"), trigger_submit: true)}
  end
end
