defmodule BlindShop.EmailTracker do
  @moduledoc """
  Tracks email delivery attempts and failures for monitoring and debugging.
  """

  require Logger

  @doc """
  Log email delivery attempt with outcome tracking
  """
  def track_delivery(recipient, subject, result) do
    case result do
      {:ok, _email} ->
        Logger.info("✅ EMAIL SUCCESS: #{recipient} | #{subject}")

      {:error, reason} ->
        Logger.error("❌ EMAIL FAILED: #{recipient} | #{subject} | Error: #{inspect(reason)}")

        # Log specific SES errors for better debugging
        case reason do
          %{message: message} when is_binary(message) ->
            cond do
              String.contains?(message, "MessageRejected") ->
                Logger.error("🚫 SES: Message rejected - check email content and recipient")

              String.contains?(message, "SendingQuotaExceeded") ->
                Logger.error("📊 SES: Sending quota exceeded - check AWS SES limits")

              String.contains?(message, "AccountSendingPaused") ->
                Logger.error("⏸️ SES: Account sending paused - check AWS SES status")

              String.contains?(message, "ConfigurationSetDoesNotExist") ->
                Logger.error("⚙️ SES: Configuration set issue")

              String.contains?(message, "InvalidParameterValue") ->
                Logger.error("🔧 SES: Invalid parameter - check email format")

              true ->
                Logger.error("❓ SES: Unknown error - #{message}")
            end

          _ ->
            Logger.error("❓ Unknown email error format: #{inspect(reason)}")
        end

      # If using a service like Sentry, you could report here:
      # Sentry.capture_message("Email delivery failed", extra: %{
      #   recipient: recipient,
      #   subject: subject,
      #   reason: reason
      # })

      result ->
        Logger.warning(
          "⚠️ EMAIL UNEXPECTED: #{recipient} | #{subject} | Result: #{inspect(result)}"
        )
    end

    result
  end

  @doc """
  Check if email service is configured properly
  """
  def health_check do
    mailer_config = Application.get_env(:blind_shop, BlindShop.Mailer, [])
    adapter = mailer_config[:adapter]

    case adapter do
      Swoosh.Adapters.Local ->
        Logger.info("📧 Mailer: Local (development)")
        {:ok, :local}

      Swoosh.Adapters.AmazonSES ->
        access_key = System.get_env("AWS_ACCESS_KEY_ID")
        secret_key = System.get_env("AWS_SECRET_ACCESS_KEY")
        region = System.get_env("AWS_REGION") || mailer_config[:region]

        cond do
          is_nil(access_key) ->
            Logger.error("❌ AWS_ACCESS_KEY_ID not configured for SES")
            {:error, :missing_access_key}

          is_nil(secret_key) ->
            Logger.error("❌ AWS_SECRET_ACCESS_KEY not configured for SES")
            {:error, :missing_secret_key}

          is_nil(region) ->
            Logger.error("❌ AWS_REGION not configured for SES")
            {:error, :missing_region}

          true ->
            Logger.info("📧 Mailer: Amazon SES (#{region})")
            {:ok, :amazon_ses}
        end

      Swoosh.Adapters.Postmark ->
        api_key = System.get_env("POSTMARK_API_KEY")

        if api_key do
          Logger.info("📧 Mailer: Postmark (production)")
          {:ok, :postmark}
        else
          Logger.error("❌ Postmark API key not configured")
          {:error, :missing_api_key}
        end

      nil ->
        Logger.error("❌ No mailer adapter configured")
        {:error, :no_adapter}

      other ->
        Logger.info("📧 Mailer: #{inspect(other)}")
        {:ok, :other}
    end
  end
end
