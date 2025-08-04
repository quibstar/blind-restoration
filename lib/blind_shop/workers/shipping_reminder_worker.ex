defmodule BlindShop.Workers.ShippingReminderWorker do
  @moduledoc """
  Oban worker that checks for orders that need shipping reminders
  """
  
  use Oban.Worker, queue: :emails, max_attempts: 3
  
  alias BlindShop.Orders
  alias BlindShop.Repo
  alias BlindShop.Emails.OrderNotifier
  
  import Ecto.Query
  require Logger
  
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Checking for orders that need shipping reminders...")
    
    # Find orders that are pending for more than 3 days
    three_days_ago = DateTime.utc_now() |> DateTime.add(-3, :day)
    
    pending_orders = 
      Orders.Order
      |> where([o], o.status == "pending")
      |> where([o], o.inserted_at < ^three_days_ago)
      |> where([o], is_nil(o.last_reminder_sent_at) or o.last_reminder_sent_at < ^three_days_ago)
      |> Repo.all()
      |> Repo.preload(:user)
    
    reminder_results = 
      Enum.map(pending_orders, fn order ->
        case send_reminder(order) do
          {:ok, _} ->
            Logger.info("Sent shipping reminder for order ##{order.id}")
            :ok
          {:error, reason} ->
            Logger.error("Failed to send reminder for order ##{order.id}: #{inspect(reason)}")
            :error
        end
      end)
    
    # Count results
    successful = Enum.count(reminder_results, &(&1 == :ok))
    failed = Enum.count(reminder_results, &(&1 == :error))
    
    Logger.info("Processed #{length(pending_orders)} pending orders: #{successful} successful, #{failed} failed")
    
    if failed > 0 do
      {:error, "#{failed} reminders failed to send"}
    else
      :ok
    end
  end
  
  defp send_reminder(order) do
    with {:ok, _email} <- OrderNotifier.send_shipping_reminder(order),
         {:ok, _order} <- update_reminder_timestamp(order) do
      {:ok, :sent}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end
  
  defp update_reminder_timestamp(order) do
    order
    |> Ecto.Changeset.change(%{last_reminder_sent_at: DateTime.utc_now()})
    |> Repo.update()
  end
end