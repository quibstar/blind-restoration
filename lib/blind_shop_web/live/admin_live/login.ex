defmodule BlindShopWeb.AdminLive.Login do
  use BlindShopWeb, :live_view

  require Logger
  alias BlindShop.Admins

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm my-12 bg-base-100 p-4 rounded shadow">
        <div class="text-center">
          <.header>
            <p>Log in</p>
            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                <%!-- Don't have an account? <.link
                  navigate={~p"/admins/register"}
                  class="font-semibold text-brand hover:underline"
                  phx-no-format
                >Sign up</.link> for an account now. --%>
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/admins/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider">or</div>

        <%!-- <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/admins/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            Log in and stay logged in <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">
            Log in only this time
          </.button>
        </.form> --%>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:admin), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "admin")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"admin" => %{"email" => email}}, socket) do
    Logger.info("Magic login attempt for email: #{email}")

    case Admins.get_admin_by_email(email) do
      nil ->
        Logger.warning("No admin found for email: #{email}")

      admin ->
        Logger.info("Admin found: #{admin.id}, sending login instructions...")

        case Admins.deliver_login_instructions(admin, &url(~p"/admins/log-in/#{&1}")) do
          {:ok, result} ->
            Logger.info("Login instructions sent successfully: #{inspect(result)}")

          {:error, reason} ->
            Logger.error("Failed to send login instructions: #{inspect(reason)}")

          result ->
            Logger.info("Login instructions result: #{inspect(result)}")
        end
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/admins/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:blind_shop, BlindShop.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
