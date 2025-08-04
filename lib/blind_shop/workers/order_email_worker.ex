defmodule BlindShop.Workers.OrderEmailWorker do
  @moduledoc """
  Oban worker for sending order-related emails asynchronously
  """
  
  use Oban.Worker, queue: :emails, max_attempts: 3
  
  alias BlindShop.Emails.OrderNotifier
  alias BlindShop.Orders
  alias BlindShop.Accounts
  
  require Logger
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email_type" => email_type, "order_id" => order_id}}) do
    order = Orders.get_order!(order_id)
    _user = Accounts.get_user!(order.user_id)
    
    case email_type do
      "order_confirmation" -> 
        OrderNotifier.send_order_confirmation(order)
        
      "order_processing" -> 
        OrderNotifier.send_order_processing(order)
        
      "order_shipped" -> 
        OrderNotifier.send_order_shipped(order)
        
      "order_completed" -> 
        OrderNotifier.send_order_completed(order)
        
      "shipping_reminder" -> 
        OrderNotifier.send_shipping_reminder(order)
        
      _ -> 
        {:error, "Unknown email type: #{email_type}"}
    end
    |> case do
      {:ok, _} -> 
        Logger.info("Successfully sent #{email_type} email for order ##{order_id}")
        :ok
        
      {:error, reason} -> 
        Logger.error("Failed to send #{email_type} email for order ##{order_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @doc """
  Enqueue an order confirmation email
  """
  def enqueue_order_confirmation(order_id, opts \\ []) do
    %{email_type: "order_confirmation", order_id: order_id}
    |> new(opts)
    |> Oban.insert()
  end
  
  @doc """
  Enqueue an order processing email
  """
  def enqueue_order_processing(order_id, opts \\ []) do
    %{email_type: "order_processing", order_id: order_id}
    |> new(opts)
    |> Oban.insert()
  end
  
  @doc """
  Enqueue an order shipped email
  """
  def enqueue_order_shipped(order_id, opts \\ []) do
    %{email_type: "order_shipped", order_id: order_id}
    |> new(opts)
    |> Oban.insert()
  end
  
  @doc """
  Enqueue an order completed email
  """
  def enqueue_order_completed(order_id, opts \\ []) do
    %{email_type: "order_completed", order_id: order_id}
    |> new(opts)
    |> Oban.insert()
  end
  
  @doc """
  Enqueue a shipping reminder email
  """
  def enqueue_shipping_reminder(order_id, opts \\ []) do
    %{email_type: "shipping_reminder", order_id: order_id}
    |> new(opts)
    |> Oban.insert()
  end
end