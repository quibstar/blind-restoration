defmodule BlindShop.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias BlindShop.Repo

  alias BlindShop.Orders.Order
  alias BlindShop.Accounts.Scope
  alias BlindShop.Workers.OrderEmailWorker


  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders(scope)
      [%Order{}, ...]

  """
  def list_orders(%Scope{} = scope) do
    Order
    |> where([o], o.user_id == ^scope.user.id)
    |> preload(:order_line_items)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(%Scope{} = scope, id) do
    Order
    |> where([o], o.id == ^id and o.user_id == ^scope.user.id)
    |> preload(:order_line_items)
    |> Repo.one!()
  end

  @doc """
  Gets a single order by ID (for workers/internal use).
  """
  def get_order!(id) do
    Order
    |> preload(:order_line_items)
    |> Repo.get!(id)
  end

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(%Scope{} = scope, attrs) do
    attrs = Map.put(attrs, "user_id", scope.user.id)
    
    with {:ok, order = %Order{}} <-
           %Order{}
           |> Order.changeset(attrs)
           |> Repo.insert() do
      
      # Enqueue order confirmation email
      OrderEmailWorker.enqueue_order_confirmation(order.id)
      
      # Broadcast order creation
      broadcast_order_change({:ok, order}, :created)
    end
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Scope{} = scope, %Order{} = order, attrs) do
    true = order.user_id == scope.user.id
    old_status = order.status

    with {:ok, updated_order = %Order{}} <-
           order
           |> Order.changeset(attrs)
           |> Repo.update() do
      
      # Enqueue status change notification if status changed
      if old_status != updated_order.status do
        case updated_order.status do
          "processing" -> OrderEmailWorker.enqueue_order_processing(updated_order.id)
          "shipped" -> OrderEmailWorker.enqueue_order_shipped(updated_order.id)
          "completed" -> OrderEmailWorker.enqueue_order_completed(updated_order.id)
          _ -> :ok
        end
      end
      
      # Broadcast order update
      broadcast_order_change({:ok, updated_order}, :updated)
    end
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Scope{} = scope, %Order{} = order) do
    true = order.user_id == scope.user.id

    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Scope{} = scope, %Order{} = order, attrs \\ %{}) do
    true = order.user_id == scope.user.id

    Order.changeset(order, attrs)
  end

  @doc """
  Subscribe to order updates for a user.
  """
  def subscribe_orders(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(BlindShop.PubSub, "orders:#{scope.user.id}")
  end

  @doc """
  Broadcast order updates to subscribers.
  """
  def broadcast_order_change({:ok, order}, event) do
    Phoenix.PubSub.broadcast(BlindShop.PubSub, "orders:#{order.user_id}", {event, order})
    {:ok, order}
  end

  def broadcast_order_change(error, _event), do: error
end
