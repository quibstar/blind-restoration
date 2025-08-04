defmodule BlindShop.Payments.InvoiceService do
  @moduledoc """
  Service for generating and managing invoices for completed repairs.
  """

  alias BlindShop.Admin.Orders
  alias BlindShop.Accounts
  alias BlindShop.Emails.OrderNotifier
  alias BlindShop.Repo
  alias Stripe.Checkout.Session

  @doc """
  Generate and send invoice for a completed repair order.
  """
  def generate_invoice(order) do
    case create_invoice_checkout_session(order) do
      {:ok, checkout_session} ->
        case update_order_with_invoice(order, checkout_session) do
          {:ok, updated_order} ->
            # Send invoice email
            case send_invoice_email(updated_order, checkout_session.url) do
              {:ok, _} ->
                {:ok, updated_order}

              {:error, email_error} ->
                require Logger
                Logger.warning("Invoice created but email failed: #{inspect(email_error)}")
                # Still return success since payment link works
                {:ok, updated_order}
            end

          {:error, update_error} ->
            require Logger
            Logger.error("Failed to update order with invoice: #{inspect(update_error)}")
            {:error, update_error}
        end

      {:error, stripe_error} ->
        require Logger
        Logger.error("Failed to create Stripe checkout session: #{inspect(stripe_error)}")
        {:error, stripe_error}
    end
  end

  defp create_invoice_checkout_session(order) do
    user = order.user || Accounts.get_user!(order.user_id)

    # Build URLs
    base_url = BlindShopWeb.Endpoint.url()
    success_url = "#{base_url}/orders/invoice-paid?session_id={CHECKOUT_SESSION_ID}"
    cancel_url = "#{base_url}/orders/#{order.id}"

    # Use StripeService to create the session with invoice parameters
    create_invoice_session(order, user, success_url, cancel_url)
  end

  defp create_invoice_session(order, user, success_url, cancel_url) do
    # Create line items for the order
    line_items = [
      %{
        price_data: %{
          currency: "usd",
          product_data: %{
            name: "Blind Repair Service - #{String.capitalize(order.blind_type)}",
            description:
              "#{order.width}\" × #{order.height}\" - Quantity: #{order.quantity} - #{String.capitalize(order.service_level)} service"
          },
          unit_amount: Decimal.to_integer(Decimal.mult(order.total_price, 100))
        },
        quantity: 1
      }
    ]

    # Add shipping cost as separate line item if applicable
    shipping_cost = order.shipping_cost || Decimal.new("0")

    line_items =
      if order.is_returnable && Decimal.compare(shipping_cost, Decimal.new("0")) == :gt do
        shipping_item = %{
          price_data: %{
            currency: "usd",
            product_data: %{
              name: "Return Shipping",
              description: "Shipping cost to return your repaired blinds"
            },
            unit_amount: Decimal.to_integer(Decimal.mult(shipping_cost, 100))
          },
          quantity: 1
        }

        line_items ++ [shipping_item]
      else
        line_items
      end

    # Create session parameters
    session_params = %{
      payment_method_types: ["card"],
      line_items: line_items,
      mode: "payment",
      success_url: success_url,
      cancel_url: cancel_url,
      customer_email: user.email,
      metadata: %{
        "order_id" => to_string(order.id),
        "user_id" => to_string(user.id),
        "invoice_payment" => "true"
      }
    }

    # Try to create Stripe session, with fallback for development
    case Application.get_env(:stripity_stripe, :api_key) do
      nil ->
        # No Stripe key configured - create mock session for development
        create_mock_session(session_params)

      api_key when is_binary(api_key) and api_key != "" ->
        # Stripe is configured - create real session
        create_stripe_session(session_params)

      _ ->
        # Invalid configuration
        {:error, "Stripe API key not properly configured"}
    end
  end

  defp create_stripe_session(session_params) do
    try do
      case Session.create(session_params) do
        {:ok, session} -> {:ok, session}
        {:error, error} -> {:error, error}
      end
    rescue
      error ->
        require Logger
        Logger.error("Stripe invoice creation error: #{inspect(error)}")
        {:error, "Stripe configuration issue - check API keys"}
    end
  end

  defp create_mock_session(session_params) do
    # Create a mock session for development/testing
    mock_session = %{
      id: "cs_test_mock_#{:rand.uniform(100_000)}",
      url:
        "#{session_params.success_url |> String.replace("{CHECKOUT_SESSION_ID}", "cs_test_mock_session")}",
      payment_intent: %{id: "pi_test_mock_#{:rand.uniform(100_000)}"},
      metadata: session_params.metadata
    }

    require Logger
    Logger.info("Created mock Stripe session for development: #{mock_session.id}")
    Logger.info("Mock payment URL: #{mock_session.url}")

    {:ok, mock_session}
  end

  defp update_order_with_invoice(order, checkout_session) do
    attrs = %{
      status: "invoice_sent",
      payment_status: "invoice_sent",
      invoice_id: checkout_session.id,
      invoice_sent_at: DateTime.utc_now(),
      checkout_session_id: checkout_session.id
    }

    # Admin context can update orders directly
    Orders.update_order(order, attrs)
  end

  defp send_invoice_email(order, payment_url) do
    # Send the invoice email using the existing OrderNotifier
    case OrderNotifier.send_invoice_ready(order, payment_url) do
      {:ok, _email} ->
        {:ok, :sent}

      {:error, reason} ->
        require Logger
        Logger.error("Failed to send invoice email for order ##{order.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Handle successful invoice payment from Stripe webhook
  """
  def handle_invoice_payment(session_id) do
    try do
      with {:ok, session} <- Session.retrieve(session_id, %{expand: ["payment_intent"]}),
           {:ok, order} <- get_order_from_session(session),
           {:ok, updated_order} <- mark_order_paid(order, session) do
        # Update status to paid and ready for shipping
        {:ok, updated_order}
      else
        error -> error
      end
    rescue
      error ->
        require Logger
        Logger.error("Stripe payment retrieval error: #{inspect(error)}")
        {:error, "Stripe configuration issue - check API keys"}
    end
  end

  defp get_order_from_session(session) do
    case session.metadata["order_id"] do
      nil ->
        {:error, "No order ID in session metadata"}

      order_id when is_binary(order_id) ->
        case Integer.parse(order_id) do
          {id, ""} -> {:ok, Orders.get_order!(id)}
          _ -> {:error, "Invalid order ID format"}
        end

      order_id when is_integer(order_id) ->
        {:ok, Orders.get_order!(order_id)}

      _ ->
        {:error, "Invalid order ID type"}
    end
  end

  defp mark_order_paid(order, session) do
    # Safely extract payment intent ID
    payment_intent_id =
      case session.payment_intent do
        %{id: id} when is_binary(id) -> id
        id when is_binary(id) -> id
        _ -> nil
      end

    attrs = %{
      status: "paid",
      payment_status: "paid",
      payment_intent_id: payment_intent_id,
      paid_at: DateTime.utc_now()
    }

    Orders.update_order(order, attrs)
  end

  @doc """
  Generate invoice using line items from the database instead of hardcoded calculations.
  """
  def generate_invoice_with_line_items(order) do
    # Preload line items
    order_with_line_items = Repo.preload(order, :invoice_line_items)
    
    case create_invoice_checkout_session_with_line_items(order_with_line_items) do
      {:ok, checkout_session} ->
        case update_order_with_invoice(order, checkout_session) do
          {:ok, updated_order} ->
            # Send invoice email
            case send_invoice_email(updated_order, checkout_session.url) do
              {:ok, _} ->
                {:ok, updated_order}

              {:error, email_error} ->
                require Logger
                Logger.warning("Invoice created but email failed: #{inspect(email_error)}")
                # Still return success since payment link works
                {:ok, updated_order}
            end

          {:error, update_error} ->
            require Logger
            Logger.error("Failed to update order with invoice: #{inspect(update_error)}")
            {:error, update_error}
        end

      {:error, stripe_error} ->
        require Logger
        Logger.error("Failed to create Stripe checkout session: #{inspect(stripe_error)}")
        {:error, stripe_error}
    end
  end

  defp create_invoice_checkout_session_with_line_items(order) do
    user = order.user || Accounts.get_user!(order.user_id)

    # Build URLs
    base_url = BlindShopWeb.Endpoint.url()
    success_url = "#{base_url}/orders/invoice-paid?session_id={CHECKOUT_SESSION_ID}"
    cancel_url = "#{base_url}/orders/#{order.id}"

    # Use line items from database to create session
    create_invoice_session_with_line_items(order, user, success_url, cancel_url)
  end

  defp create_invoice_session_with_line_items(order, user, success_url, cancel_url) do
    # Create line items from database records
    line_items = Enum.map(order.invoice_line_items, fn line_item ->
      %{
        price_data: %{
          currency: "usd",
          product_data: %{
            name: line_item.description,
            description: "Quantity: #{line_item.quantity}"
          },
          unit_amount: Decimal.to_integer(Decimal.mult(line_item.unit_price, 100))
        },
        quantity: line_item.quantity
      }
    end)

    # Add shipping cost as separate line item if applicable
    shipping_cost = order.shipping_cost || Decimal.new("0")

    line_items =
      if order.is_returnable && Decimal.compare(shipping_cost, Decimal.new("0")) == :gt do
        shipping_item = %{
          price_data: %{
            currency: "usd",
            product_data: %{
              name: "Return Shipping",
              description: "Shipping cost to return your repaired blinds"
            },
            unit_amount: Decimal.to_integer(Decimal.mult(shipping_cost, 100))
          },
          quantity: 1
        }

        line_items ++ [shipping_item]
      else
        line_items
      end

    # Create session parameters
    session_params = %{
      payment_method_types: ["card"],
      line_items: line_items,
      mode: "payment",
      success_url: success_url,
      cancel_url: cancel_url,
      customer_email: user.email,
      metadata: %{
        "order_id" => to_string(order.id),
        "user_id" => to_string(user.id),
        "invoice_payment" => "true"
      }
    }

    # Try to create Stripe session, with fallback for development
    case Application.get_env(:stripity_stripe, :api_key) do
      nil ->
        # No Stripe key configured - create mock session for development
        create_mock_session(session_params)

      api_key when is_binary(api_key) and api_key != "" ->
        # Stripe is configured - create real session
        create_stripe_session(session_params)

      _ ->
        # Invalid configuration
        {:error, "Stripe API key not properly configured"}
    end
  end
end
