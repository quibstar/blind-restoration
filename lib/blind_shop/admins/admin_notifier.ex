defmodule BlindShop.Admins.AdminNotifier do
  import Swoosh.Email
  require Logger

  alias BlindShop.Mailer
  alias BlindShop.Admins.Admin
  alias BlindShop.EmailTracker

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    Logger.info("Attempting to send email to: #{recipient}, subject: #{subject}")

    # Log the mailer configuration
    mailer_config = Application.get_env(:blind_shop, BlindShop.Mailer, [])
    Logger.info("Mailer adapter: #{inspect(mailer_config[:adapter])}")

    email =
      new()
      |> to(recipient)
      |> from({"BlindShop", "support@blindrestoration.com"})
      |> subject(subject)
      |> text_body(body)

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

  @doc """
  Deliver instructions to update a admin email.
  """
  def deliver_update_email_instructions(admin, url) do
    deliver(admin.email, "Update email instructions", """

    ==============================

    Hi #{admin.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(admin, url) do
    case admin do
      %Admin{confirmed_at: nil} -> deliver_confirmation_instructions(admin, url)
      _ -> deliver_magic_link_instructions(admin, url)
    end
  end

  defp deliver_magic_link_instructions(admin, url) do
    deliver(admin.email, "Log in instructions", """

    ==============================

    Hi #{admin.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(admin, url) do
    deliver(admin.email, "Confirmation instructions", """

    ==============================

    Hi #{admin.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
