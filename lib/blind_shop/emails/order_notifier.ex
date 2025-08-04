defmodule BlindShop.Emails.OrderNotifier do
  @moduledoc """
  Handles email notifications for order events
  """
  
  alias BlindShop.Mailer
  alias BlindShop.Orders.Order
  alias BlindShop.Accounts
  alias BlindShopWeb.Emails.OrderEmail
  
  @doc """
  Sends order confirmation email when a new order is created
  """
  def send_order_confirmation(%Order{user_id: user_id} = order) do
    user = Accounts.get_user!(user_id)
    
    OrderEmail.order_confirmation(order, user)
    |> Mailer.deliver()
  end
  
  @doc """
  Sends notification when order status changes to processing
  """
  def send_order_processing(%Order{user_id: user_id} = order) do
    user = Accounts.get_user!(user_id)
    
    OrderEmail.order_processing(order, user)
    |> Mailer.deliver()
  end
  
  @doc """
  Sends notification when order is shipped with tracking info
  """
  def send_order_shipped(%Order{user_id: user_id} = order) do
    user = Accounts.get_user!(user_id)
    
    OrderEmail.order_shipped(order, user)
    |> Mailer.deliver()
  end
  
  @doc """
  Sends notification when order is completed
  """
  def send_order_completed(%Order{user_id: user_id} = order) do
    user = Accounts.get_user!(user_id)
    
    OrderEmail.order_completed(order, user)
    |> Mailer.deliver()
  end
  
  @doc """
  Sends reminder to ship blinds if order is still pending after 3 days
  """
  def send_shipping_reminder(%Order{user_id: user_id} = order) do
    user = Accounts.get_user!(user_id)
    
    OrderEmail.shipping_reminder(order, user)
    |> Mailer.deliver()
  end
  
  @doc """
  Sends invoice ready notification with payment link
  """
  def send_invoice_ready(%Order{user_id: user_id} = order, payment_url) do
    user = Accounts.get_user!(user_id)
    
    OrderEmail.invoice_ready(order, user, payment_url)
    |> Mailer.deliver()
  end

  @doc """
  Handles status change notifications
  """
  def notify_status_change(order, old_status, new_status) do
    case {old_status, new_status} do
      {_, "processing"} -> send_order_processing(order)
      {_, "shipped"} -> send_order_shipped(order)
      {_, "completed"} -> send_order_completed(order)
      _ -> :ok
    end
  end
end