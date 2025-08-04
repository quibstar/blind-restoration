defmodule BlindShopWeb.OrderLive.Index do
  use BlindShopWeb, :live_view

  alias BlindShop.Orders
  alias BlindShop.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto p-6">
        <.header>
          My Orders
          <:actions>
            <.link navigate={~p"/orders/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="h-5 w-5" /> New Order
            </.link>
          </:actions>
        </.header>

        <%= if @orders == [] do %>
          <div class="text-center py-12">
            <div class="text-6xl mb-4">📦</div>
            <h3 class="text-xl font-semibold mb-2">No orders yet</h3>
            <p class="text-base-content/70 mb-6">Get started by creating your first order</p>
            <.link navigate={~p"/"} class="btn btn-primary">
              Get a Quote
            </.link>
          </div>
        <% else %>
          <div class="overflow-x-auto mt-8">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Order #</th>
                  <th>Date</th>
                  <th>Items</th>
                  <th>Qty</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for order <- @orders do %>
                  <tr>
                    <td class="font-mono">#{String.pad_leading(to_string(order.id), 6, "0")}</td>
                    <td>{Calendar.strftime(order.inserted_at, "%b %d, %Y")}</td>
                    <td>{format_order_items_summary(order)}</td>
                    <td>{get_total_items_quantity(order)}</td>
                    <td class="font-semibold">${order.total_price}</td>
                    <td>
                      <% {label, class} = Order.status_badge(order.status) %>
                      <span class={"badge #{class}"}>{label}</span>
                    </td>
                    <td>
                      <.link navigate={~p"/orders/#{order}"} class="btn btn-sm btn-ghost">
                        View <.icon name="hero-arrow-right" class="h-4 w-4" />
                      </.link>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Orders.subscribe_orders(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "My Orders")
     |> assign(:orders, Orders.list_orders(socket.assigns.current_scope))}
  end

  @impl true
  def handle_info({:created, order}, socket) do
    {:noreply, assign(socket, :orders, [order | socket.assigns.orders])}
  end

  def handle_info({:updated, order}, socket) do
    orders =
      Enum.map(socket.assigns.orders, fn o ->
        if o.id == order.id, do: order, else: o
      end)

    {:noreply, assign(socket, :orders, orders)}
  end

  def handle_info({:deleted, order}, socket) do
    orders = Enum.reject(socket.assigns.orders, &(&1.id == order.id))
    {:noreply, assign(socket, :orders, orders)}
  end

  # Helper functions
  defp format_order_items_summary(order) do
    case order.order_line_items do
      [] ->
        "No items"

      [item] ->
        format_blind_type(item.blind_type)

      items when length(items) <= 2 ->
        items
        |> Enum.map(&format_blind_type(&1.blind_type))
        |> Enum.join(", ")

      items ->
        first_item = items |> List.first() |> then(&format_blind_type(&1.blind_type))
        "#{first_item}, +#{length(items) - 1} more"
    end
  end

  defp get_total_items_quantity(order) do
    case order.order_line_items do
      [] -> 0
      items -> Enum.reduce(items, 0, fn item, acc -> acc + (item.quantity || 1) end)
    end
  end

  defp format_blind_type(blind_type) do
    case blind_type do
      "mini" -> "Mini"
      "vertical" -> "Vertical"
      "honeycomb" -> "Honeycomb"
      "wood" -> "Wood"
      "roman" -> "Roman"
      _ -> String.capitalize(blind_type || "Unknown")
    end
  end
end
