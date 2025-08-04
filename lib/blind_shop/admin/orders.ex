defmodule BlindShop.Admin.Orders do
  @moduledoc """
  Admin context for managing orders with full access across all users.
  """

  import Ecto.Query, warn: false
  alias BlindShop.Repo

  alias BlindShop.Orders.Order
  alias BlindShop.Accounts.Scope
  alias BlindShop.Workers.OrderEmailWorker


  @doc """
  Returns the list of all orders for admin view.
  """
  def list_orders() do
    Order
    |> preload([:user, :order_line_items])
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single order by ID with user preloaded.
  Admin has access to any order.
  """
  def get_order!(id) do
    Order
    |> preload([:user, :order_line_items])
    |> Repo.get!(id)
  end

  @doc """
  Updates an order from admin context.
  Admin can update any order and will broadcast to appropriate channels.
  """
  def update_order(%Order{} = order, attrs) do
    old_status = order.status

    with {:ok, updated_order = %Order{}} <-
           order
           |> Order.changeset(attrs)
           |> Repo.update() do
      
      # Reload with all associations for complete data
      updated_order = Repo.preload(updated_order, [:user, :order_line_items], force: true)
      
      # Enqueue status change notification if status changed
      if old_status != updated_order.status do
        case updated_order.status do
          "shipping_back" -> OrderEmailWorker.enqueue_order_shipped(updated_order.id)
          "completed" -> OrderEmailWorker.enqueue_order_completed(updated_order.id)
          _ -> :ok
        end
      end
      
      {:ok, updated_order}
    end
  end

  @doc """
  Gets orders by status for admin dashboard.
  """
  def get_orders_by_status(status) do
    Order
    |> where([o], o.status == ^status)
    |> preload([:user, :order_line_items])
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets orders that need attention (status-based filtering).
  """
  def get_orders_needing_attention() do
    Order
    |> where([o], o.status in ["received", "assessed", "repairing"])
    |> preload(:user)
    |> order_by([o], asc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets orders awaiting payment.
  """
  def get_orders_awaiting_payment() do
    Order
    |> where([o], o.status == "invoice_sent")
    |> preload(:user)
    |> order_by([o], desc: o.invoice_sent_at)
    |> Repo.all()
  end

  @doc """
  Gets order statistics for admin dashboard.
  """
  def get_order_statistics() do
    base_query = from(o in Order)
    
    %{
      total_orders: Repo.aggregate(base_query, :count, :id),
      pending_orders: Repo.aggregate(where(base_query, status: "pending"), :count, :id),
      active_orders: Repo.aggregate(where(base_query, status: ^["received", "assessed", "repairing"]), :count, :id),
      awaiting_payment: Repo.aggregate(where(base_query, status: "invoice_sent"), :count, :id),
      completed_orders: Repo.aggregate(where(base_query, status: "completed"), :count, :id),
      total_revenue: get_total_revenue(),
      avg_order_value: get_average_order_value()
    }
  end

  defp get_total_revenue() do
    Order
    |> where([o], o.status in ["paid", "shipping_back", "completed"])
    |> select([o], sum(o.total_price))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0")
      amount -> amount
    end
  end

  defp get_average_order_value() do
    case Repo.aggregate(Order, :avg, :total_price) do
      nil -> Decimal.new("0")
      %Decimal{} = avg -> avg
      avg when is_float(avg) -> Decimal.from_float(avg)
    end
  end

  @doc """
  Search orders by customer email or order ID.
  """
  def search_orders(query) when is_binary(query) do
    # Try to parse as order ID first
    case Integer.parse(query) do
      {order_id, ""} ->
        # Exact order ID match
        Order
        |> where([o], o.id == ^order_id)
        |> preload([:user, :order_line_items])
        |> Repo.all()
      
      _ ->
        # Search by customer email or name
        Order
        |> join(:inner, [o], u in assoc(o, :user))
        |> where([o, u], 
          ilike(u.email, ^"%#{query}%") or 
          ilike(u.first_name, ^"%#{query}%") or 
          ilike(u.last_name, ^"%#{query}%")
        )
        |> preload([:user, :order_line_items])
        |> order_by([o], desc: o.inserted_at)
        |> Repo.all()
    end
  end

  @doc """
  Cancel an order (admin action).
  """
  def cancel_order(%Order{} = order, reason \\ nil) do
    attrs = %{
      status: "cancelled",
      notes: if(reason, do: "Cancelled: #{reason}", else: order.notes)
    }
    
    update_order(order, attrs)
  end

  @doc """
  Update order notes (admin action).
  """
  def update_order_notes(%Order{} = order, notes) do
    update_order(order, %{notes: notes})
  end
end