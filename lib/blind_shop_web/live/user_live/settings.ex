defmodule BlindShopWeb.UserLive.Settings do
  use BlindShopWeb, :live_view

  on_mount {BlindShopWeb.UserAuth, :require_sudo_mode}

  alias BlindShop.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm my-12 bg-base-100 p-4 rounded shadow">
        <.header>
          Account Settings
          <:subtitle>Manage your account email address and password settings</:subtitle>
        </.header>

        <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
          />
          <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
        </.form>

        <div class="divider" />

        <.form
          for={@password_form}
          id="password_form"
          action={~p"/users/update-password"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            autocomplete="username"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
          />
          <.button variant="primary" phx-disable-with="Saving...">
            Save Password
          </.button>
        </.form>

        <div class="divider" />

        <!-- Account Deletion Section -->
        <div class="bg-error/10 border border-error/20 rounded-lg p-4">
          <h3 class="text-lg font-semibold text-error mb-2">Delete Account</h3>
          <p class="text-sm text-base-content/70 mb-4">
            Permanently remove your account and personal information. Your order history will be preserved for business records but anonymized.
          </p>
          
          <details class="collapse collapse-arrow bg-base-200 mb-4">
            <summary class="collapse-title text-sm font-medium">What happens when I delete my account?</summary>
            <div class="collapse-content text-sm">
              <ul class="list-disc list-inside space-y-1 text-base-content/70">
                <li>Your personal information (name, email, address) will be permanently removed</li>
                <li>You will be immediately logged out and cannot log back in</li>
                <li>Order history remains for business/tax purposes but is anonymized</li>
                <li>This action cannot be undone</li>
              </ul>
            </div>
          </details>

          <div class="flex gap-2">
            <%= if @show_feedback_form do %>
              <!-- Feedback Form -->
              <div class="w-full">
                <h4 class="font-semibold mb-3">Help Us Improve (Optional)</h4>
                <.form for={@feedback_form} id="feedback_form" phx-submit="submit_feedback_and_delete" phx-change="validate_feedback">
                  
                  <!-- Primary reason for leaving -->
                  <.input
                    field={@feedback_form[:reason]}
                    type="select"
                    label="Primary reason for deleting your account:"
                    options={[
                      {"I no longer need the service", "no_longer_needed"},
                      {"I found a better alternative", "found_alternative"},
                      {"The service didn't meet my expectations", "unmet_expectations"},
                      {"Too expensive", "too_expensive"},
                      {"Poor customer service", "poor_service"},
                      {"Technical issues", "technical_issues"},
                      {"Privacy concerns", "privacy_concerns"},
                      {"Other", "other"}
                    ]}
                    prompt="Select a reason (optional)"
                  />

                  <!-- Satisfaction ratings -->
                  <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                    <.input
                      field={@feedback_form[:satisfaction_rating]}
                      type="select"
                      label="Overall satisfaction (1-5):"
                      options={[
                        {"5 - Very Satisfied", 5},
                        {"4 - Satisfied", 4},
                        {"3 - Neutral", 3},
                        {"2 - Dissatisfied", 2},
                        {"1 - Very Dissatisfied", 1}
                      ]}
                      prompt="Rate (optional)"
                    />

                    <.input
                      field={@feedback_form[:service_rating]}
                      type="select"
                      label="Service quality (1-5):"
                      options={[
                        {"5 - Excellent", 5},
                        {"4 - Good", 4},
                        {"3 - Average", 3},
                        {"2 - Poor", 2},
                        {"1 - Very Poor", 1}
                      ]}
                      prompt="Rate (optional)"
                    />

                    <.input
                      field={@feedback_form[:recommend_rating]}
                      type="select"
                      label="Recommend to others (1-10):"
                      options={Enum.map(10..1, fn n -> {"#{n}", n} end)}
                      prompt="Rate (optional)"
                    />
                  </div>

                  <!-- Comments -->
                  <.input
                    field={@feedback_form[:comments]}
                    type="textarea"
                    label="Additional comments:"
                    placeholder="Tell us about your experience..."
                    rows="3"
                  />

                  <.input
                    field={@feedback_form[:improvement_suggestions]}
                    type="textarea"
                    label="How could we improve?"
                    placeholder="What would have made you stay?"
                    rows="3"
                  />

                  <div class="flex gap-2 mt-6">
                    <.button type="submit" class="btn-error" phx-disable-with="Deleting...">
                      Submit Feedback & Delete Account
                    </.button>
                    <.button type="button" class="btn-ghost" phx-click="cancel_feedback">
                      Cancel
                    </.button>
                  </div>
                </.form>
              </div>
            <% else %>
              <.button 
                class="btn-error btn-outline" 
                phx-click="show_feedback_form"
                phx-disable-with="Loading..."
              >
                Delete My Account
              </.button>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    feedback_changeset = Accounts.change_account_deletion_feedback(%Accounts.AccountDeletionFeedback{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:feedback_form, to_form(feedback_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:show_feedback_form, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("show_feedback_form", _params, socket) do
    {:noreply, assign(socket, show_feedback_form: true)}
  end

  def handle_event("cancel_feedback", _params, socket) do
    {:noreply, assign(socket, show_feedback_form: false)}
  end

  def handle_event("validate_feedback", %{"account_deletion_feedback" => feedback_params}, socket) do
    feedback_form =
      %Accounts.AccountDeletionFeedback{}
      |> Accounts.change_account_deletion_feedback(feedback_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, feedback_form: feedback_form)}
  end

  def handle_event("submit_feedback_and_delete", %{"account_deletion_feedback" => feedback_params}, socket) do
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.delete_user_account_with_feedback(user, feedback_params) do
      {:ok, _deleted_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your feedback. Your account has been deleted successfully.")
         |> redirect(to: ~p"/")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an error deleting your account. Please try again or contact support.")}
    end
  end

  # Keep the old delete_account handler for backwards compatibility
  def handle_event("delete_account", _params, socket) do
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.delete_user_account(user) do
      {:ok, _deleted_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your account has been deleted successfully.")
         |> redirect(to: ~p"/")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an error deleting your account. Please try again or contact support.")}
    end
  end
end
