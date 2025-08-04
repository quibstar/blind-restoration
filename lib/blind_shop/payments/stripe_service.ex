defmodule BlindShop.Payments.StripeService do
  @moduledoc """
  Service module for Stripe payment operations
  """

  alias Stripe.Checkout.Session
  alias BlindShop.Orders.Order

  @doc """
  Creates a Stripe checkout session for an order
  """
  def create_checkout_session(%Order{} = order, success_url, cancel_url) do
    line_items = [
      %{
        price_data: %{
          currency: "usd",
          product_data: %{
            name: "Blind Repair Service",
            description: "#{String.capitalize(order.blind_type)} blind repair - #{order.width}\" × #{order.height}\" (Qty: #{order.quantity})"
          },
          unit_amount: price_to_cents(order.total_price)
        },
        quantity: 1
      }
    ]

    params = %{
      payment_method_types: ["card"],
      line_items: line_items,
      mode: "payment",
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: %{
        order_data: encode_order_data(order)
      },
      customer_email: order.user.email
    }

    try do
      case Session.create(params) do
        {:ok, session} -> {:ok, session}
        {:error, error} -> {:error, error}
      end
    rescue
      error -> 
        require Logger
        Logger.error("Stripe checkout session creation error: #{inspect(error)}")
        {:error, "Stripe configuration issue - check API keys"}
    end
  end

  @doc """
  Creates a checkout session with order attributes (for new orders)
  """
  def create_checkout_session(order_attrs, user, success_url, cancel_url) do
    total_price = Decimal.new(order_attrs["total_price"] || "0")
    
    line_items = [
      %{
        price_data: %{
          currency: "usd",
          product_data: %{
            name: "Blind Repair Service",
            description: "#{String.capitalize(order_attrs["blind_type"] || "blind")} repair - #{order_attrs["width"]}\" × #{order_attrs["height"]}\" (Qty: #{order_attrs["quantity"] || 1})"
          },
          unit_amount: price_to_cents(total_price)
        },
        quantity: 1
      }
    ]

    params = %{
      payment_method_types: ["card"],
      line_items: line_items,
      mode: "payment",
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: %{
        order_data: encode_order_attrs(order_attrs, user.id)
      },
      customer_email: user.email
    }

    try do
      case Session.create(params) do
        {:ok, session} -> {:ok, session}
        {:error, error} -> {:error, error}
      end
    rescue
      error -> 
        require Logger
        Logger.error("Stripe checkout session creation error (attrs): #{inspect(error)}")
        {:error, "Stripe configuration issue - check API keys"}
    end
  end

  @doc """
  Retrieves a Stripe checkout session
  """
  def get_checkout_session(session_id) do
    try do
      case Session.retrieve(session_id) do
        {:ok, session} -> {:ok, session}
        {:error, error} -> {:error, error}
      end
    rescue
      error -> 
        require Logger
        Logger.error("Stripe session retrieval error: #{inspect(error)}")
        {:error, "Stripe configuration issue - check API keys"}
    end
  end

  @doc """
  Decodes order data from Stripe session metadata
  """
  def decode_order_data(metadata) do
    case metadata["order_data"] do
      nil -> {:error, "No order data found"}
      encoded_data -> 
        try do
          decoded = Base.decode64!(encoded_data)
          {:ok, Jason.decode!(decoded)}
        rescue
          _ -> {:error, "Invalid order data"}
        end
    end
  end

  # Private functions

  defp price_to_cents(%Decimal{} = price) do
    price
    |> Decimal.mult(100)
    |> Decimal.to_integer()
  end

  defp price_to_cents(price) when is_binary(price) do
    price
    |> Decimal.new()
    |> price_to_cents()
  end

  defp encode_order_data(%Order{} = order) do
    data = %{
      blind_type: order.blind_type,
      width: order.width,
      height: order.height,
      quantity: order.quantity,
      service_level: order.service_level,
      base_price: to_string(order.base_price),
      size_multiplier: to_string(order.size_multiplier),
      surcharge: to_string(order.surcharge),
      volume_discount: to_string(order.volume_discount),
      total_price: to_string(order.total_price),
      notes: order.notes,
      user_id: order.user_id
    }

    data
    |> Jason.encode!()
    |> Base.encode64()
  end

  defp encode_order_attrs(attrs, user_id) do
    data = Map.put(attrs, "user_id", user_id)

    data
    |> Jason.encode!()
    |> Base.encode64()
  end
end