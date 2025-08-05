defmodule BlindShop.Orders.Admin do
  @moduledoc """
  Admin functions for order management
  """

  import Ecto.Query, warn: false
  alias BlindShop.Repo
  alias BlindShop.Orders.Order
  alias BlindShop.Workers.OrderEmailWorker

  @doc """
  Updates an order status and sends appropriate notification emails
  """
  def update_order_status(%Order{} = order, new_status) when new_status in ["pending", "processing", "shipped", "completed", "cancelled"] do
    old_status = order.status
    
    changeset = Order.changeset(order, %{status: new_status})
    
    case Repo.update(changeset) do
      {:ok, updated_order} ->
        # Send notification email if status changed
        if old_status != new_status do
          case new_status do
            "processing" -> OrderEmailWorker.enqueue_order_processing(updated_order.id)
            "shipped" -> OrderEmailWorker.enqueue_order_shipped(updated_order.id)
            "completed" -> OrderEmailWorker.enqueue_order_completed(updated_order.id)
            _ -> :ok
          end
        end
        
        {:ok, updated_order}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates order with tracking information
  """
  def update_tracking_info(%Order{} = order, tracking_number, carrier \\ nil) do
    attrs = %{
      tracking_number: tracking_number,
      carrier: carrier,
      shipped_at: DateTime.utc_now()
    }
    
    # If we're adding tracking info, automatically mark as shipped
    attrs = if order.status != "shipped" do
      Map.put(attrs, :status, "shipped")
    else
      attrs
    end
    
    changeset = Order.changeset(order, attrs)
    
    case Repo.update(changeset) do
      {:ok, updated_order} ->
        # Send shipped notification
        OrderEmailWorker.enqueue_order_shipped(updated_order.id)
        {:ok, updated_order}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Adds notes to an order
  """
  def add_order_notes(%Order{} = order, notes) do
    existing_notes = order.notes || ""
    timestamp = DateTime.utc_now() |> Calendar.strftime("%m/%d/%Y %I:%M %p")
    new_notes = "#{existing_notes}\n[#{timestamp}] #{notes}" |> String.trim()
    
    changeset = Order.changeset(order, %{notes: new_notes})
    Repo.update(changeset)
  end

  @doc """
  Gets all orders with pagination and filtering
  """
  def list_orders(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    status_filter = Keyword.get(opts, :status)
    search_query = Keyword.get(opts, :search)
    
    Order
    |> apply_status_filter(status_filter)
    |> apply_search_filter(search_query)
    |> order_by([o], desc: o.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Gets order statistics for dashboard
  """
  def get_order_stats do
    orders_query = from o in Order

    %{
      total: Repo.aggregate(orders_query, :count),
      pending: orders_query |> where([o], o.status == "pending") |> Repo.aggregate(:count),
      processing: orders_query |> where([o], o.status == "processing") |> Repo.aggregate(:count),
      shipped: orders_query |> where([o], o.status == "shipped") |> Repo.aggregate(:count),
      completed: orders_query |> where([o], o.status == "completed") |> Repo.aggregate(:count),
      cancelled: orders_query |> where([o], o.status == "cancelled") |> Repo.aggregate(:count)
    }
  end

  @doc """
  Gets revenue statistics
  """
  def get_revenue_stats do
    revenue_query = from o in Order, where: o.status in ["completed", "shipped", "processing"]
    
    total_revenue = Repo.aggregate(revenue_query, :sum, :total_price) || Decimal.new(0)
    
    # This month's revenue
    now = DateTime.utc_now()
    start_of_month = %{now | day: 1, hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
    monthly_revenue = 
      revenue_query
      |> where([o], o.inserted_at >= ^start_of_month)
      |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)
    
    # This week's revenue  
    start_of_week = DateTime.utc_now() |> DateTime.add(-7, :day)
    weekly_revenue = 
      revenue_query
      |> where([o], o.inserted_at >= ^start_of_week)
      |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)
    
    %{
      total: total_revenue,
      monthly: monthly_revenue,
      weekly: weekly_revenue
    }
  end

  @doc """
  Gets orders that need attention (pending for more than 3 days)
  """
  def get_overdue_orders do
    three_days_ago = DateTime.utc_now() |> DateTime.add(-3, :day)
    
    Order
    |> where([o], o.status == "pending")
    |> where([o], o.inserted_at < ^three_days_ago)
    |> order_by([o], asc: o.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp apply_status_filter(query, nil), do: query
  defp apply_status_filter(query, status), do: where(query, [o], o.status == ^status)

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query
  defp apply_search_filter(query, search_query) do
    search_term = "%#{search_query}%"
    
    query
    |> join(:inner, [o], u in assoc(o, :user))
    |> where([o, u], 
      ilike(u.first_name, ^search_term) or
      ilike(u.last_name, ^search_term) or
      ilike(u.email, ^search_term) or
      ilike(fragment("?::text", o.id), ^search_term)
    )
  end
end