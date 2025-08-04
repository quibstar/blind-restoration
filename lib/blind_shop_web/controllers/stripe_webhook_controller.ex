defmodule BlindShopWeb.StripeWebhookController do
  use BlindShopWeb, :controller

  alias BlindShop.Orders
  alias BlindShop.Accounts
  alias BlindShop.Payments.StripeService
  alias BlindShop.Workers.OrderEmailWorker

  require Logger

  @doc """
  Handle Stripe webhook events
  """
  def handle(conn, _params) do
    with {:ok, event} <- get_stripe_event(conn),
         :ok <- handle_stripe_event(event) do
      send_resp(conn, 200, "ok")
    else
      {:error, reason} ->
        Logger.error("Stripe webhook error: #{inspect(reason)}")
        send_resp(conn, 400, "error")
    end
  end

  defp get_stripe_event(conn) do
    payload = conn.assigns.raw_body || get_raw_body(conn)
    signature = get_req_header(conn, "stripe-signature") |> List.first()
    
    case Stripe.Webhook.construct_event(payload, signature, webhook_secret()) do
      {:ok, event} -> {:ok, event}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_raw_body(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    body
  end

  defp handle_stripe_event(%{type: "checkout.session.completed"} = event) do
    session = event.data.object
    
    case StripeService.decode_order_data(session.metadata) do
      {:ok, order_data} ->
        create_order_from_payment(session, order_data)
        
      {:error, reason} ->
        Logger.error("Failed to decode order data: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp handle_stripe_event(%{type: event_type}) do
    Logger.info("Unhandled Stripe event: #{event_type}")
    :ok
  end

  defp create_order_from_payment(session, order_data) do
    user_id = order_data["user_id"]
    
    case Accounts.get_user(user_id) do
      nil ->
        Logger.error("User not found: #{user_id}")
        {:error, "User not found"}
        
      user ->
        scope = %BlindShop.Accounts.Scope{user: user}
        
        # Add payment fields to order data
        order_attrs = Map.merge(order_data, %{
          "checkout_session_id" => session.id,
          "payment_intent_id" => session.payment_intent,
          "payment_status" => "paid",
          "paid_at" => DateTime.utc_now(),
          "status" => "pending"  # Order starts as pending after payment
        })
        
        # Check if order already exists (for idempotency)
        case find_existing_order(session.id) do
          nil ->
            case Orders.create_order(scope, order_attrs) do
              {:ok, order} ->
                Logger.info("Order created successfully: #{order.id}")
                # Order confirmation email is sent automatically by create_order
                :ok
                
              {:error, changeset} ->
                Logger.error("Failed to create order: #{inspect(changeset)}")
                {:error, "Failed to create order"}
            end
            
          _existing_order ->
            Logger.info("Order already exists for session: #{session.id}")
            :ok
        end
    end
  end

  defp find_existing_order(checkout_session_id) do
    BlindShop.Repo.get_by(BlindShop.Orders.Order, checkout_session_id: checkout_session_id)
  end

  defp webhook_secret do
    Application.get_env(:stripity_stripe, :webhook_secret) ||
      System.get_env("STRIPE_WEBHOOK_SECRET")
  end
end