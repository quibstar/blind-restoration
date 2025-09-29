defmodule BlindShop.Accounts.UserNotifier do
  import Swoosh.Email
  require Logger

  alias BlindShop.Mailer
  alias BlindShop.Accounts.User
  alias BlindShop.EmailTracker

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, text_body, html_body) do
    Logger.info("Attempting to send email to: #{recipient}, subject: #{subject}")

    # Log the mailer configuration
    mailer_config = Application.get_env(:blind_shop, BlindShop.Mailer, [])
    Logger.info("Mailer adapter: #{inspect(mailer_config[:adapter])}")

    email =
      new()
      |> to(recipient)
      |> from({"BlindShop", "support@blindrestoration.com"})
      |> subject(subject)
      |> text_body(text_body)
      |> html_body(html_body)

    Logger.info("Email struct created: #{inspect(email)}")

    result =
      case Mailer.deliver(email) do
        {:ok, metadata} ->
          Logger.info("Email sent successfully: #{inspect(metadata)}")
          {:ok, email}

        {:error, reason} ->
          Logger.error("Failed to send email: #{inspect(reason)}")
          {:error, reason}

        result ->
          Logger.warning("Unexpected email delivery result: #{inspect(result)}")
          result
      end

    # Track the delivery result
    EmailTracker.track_delivery(recipient, subject, result)
    result
  end

  # Render email template with layout
  defp render_template(template_name, assigns) do
    # The path to the templates directory
    templates_path = "priv/email_templates"

    # Convert assigns to atom map for proper @ access in templates
    atom_assigns = assigns_to_atom_map(assigns)

    # Render the specific email template
    template_path = Path.join([templates_path, "auth", "#{template_name}.html.eex"])
    inner_content = EEx.eval_file(template_path, assigns: atom_assigns)

    # Render the layout with the content
    layout_assigns = Map.put(atom_assigns, :inner_content, inner_content)
    layout_path = Path.join([templates_path, "layouts", "app.html.eex"])

    EEx.eval_file(layout_path, assigns: layout_assigns)
  end

  # Convert string keys to atom keys for proper @ access in templates
  defp assigns_to_atom_map(assigns) do
    Enum.into(assigns, %{}, fn {key, value} ->
      atom_key = if is_atom(key), do: key, else: String.to_atom(key)
      {atom_key, value}
    end)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    subject = "Update Your Email Address - BlindRestoration"

    text_body = """
    Update Your Email Address

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Best regards,
    The BlindRestoration Team
    """

    html_body =
      render_template("email_update_instructions", %{
        user: user,
        url: url,
        subject: subject
      })

    deliver(user.email, subject, text_body, html_body)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    subject = "Login to Your BlindRestoration Account"

    text_body = """
    Login to Your Account

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    Best regards,
    The BlindRestoration Team
    """

    html_body =
      render_template("login_instructions", %{
        user: user,
        url: url,
        subject: subject
      })

    deliver(user.email, subject, text_body, html_body)
  end

  defp deliver_confirmation_instructions(user, url) do
    subject = "Welcome to BlindRestoration - Confirm Your Account"

    text_body = """
    Welcome to BlindRestoration!

    Hi #{user.email},

    Thank you for creating an account! Please confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    Best regards,
    The BlindRestoration Team
    """

    html_body =
      render_template("confirmation_instructions", %{
        user: user,
        url: url,
        subject: subject
      })

    deliver(user.email, subject, text_body, html_body)
  end
end
