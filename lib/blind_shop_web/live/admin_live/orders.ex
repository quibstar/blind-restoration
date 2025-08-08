defmodule BlindShopWeb.AdminLive.Orders do
  use BlindShopWeb, :live_view

  alias BlindShop.Admin.Orders, as: AdminOrders

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:status_filter, "all")
     |> assign(:search_query, "")
     |> load_orders()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    status_filter = Map.get(params, "status", "all")
    search_query = Map.get(params, "search", "")

    {:noreply,
     socket
     |> assign(:status_filter, status_filter)
     |> assign(:search_query, search_query)
     |> load_orders()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/orders?status=#{status}&search=#{socket.assigns.search_query}"
     )}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/orders?status=#{socket.assigns.status_filter}&search=#{query}"
     )}
  end

  @impl true
  def handle_event("update_status", %{"id" => id, "status" => new_status}, socket) do
    order = AdminOrders.get_order!(id)

    case AdminOrders.update_order(order, %{status: new_status}) do
      {:ok, _updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order status updated successfully")
         |> load_orders()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update order status")}
    end
  end

  defp load_orders(socket) do
    orders =
      case {socket.assigns.status_filter, socket.assigns.search_query} do
        {"all", ""} ->
          AdminOrders.list_orders()

        {status, ""} when status != "all" ->
          AdminOrders.get_orders_by_status(status)

        {"all", query} ->
          AdminOrders.search_orders(query)

        {status, query} ->
          AdminOrders.search_orders(query)
          |> Enum.filter(&(&1.status == status))
      end

    assign(socket, :orders, orders)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">Order Management</h1>
          <p class="text-base-content/70 mt-2">Track and manage customer orders</p>
        </div>
        
    <!-- Stats Summary -->
        <div class="stats shadow mb-6 bg-base-100">
          <div class="stat">
            <div class="stat-title">Total Orders</div>
            <div class="stat-value text-primary">{length(@orders)}</div>
            <div class="stat-desc">
              <%= if @status_filter != "all" do %>
                {String.capitalize(@status_filter)} orders
              <% else %>
                All statuses
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Filters and Search -->
        <div class="card bg-base-100 shadow mb-6">
          <div class="card-body">
            <div class="flex flex-col sm:flex-row gap-4">
              <!-- Status Filter -->
              <div class="dropdown">
                <div tabindex="0" role="button" class="btn btn-outline gap-2">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"
                    >
                    </path>
                  </svg>
                  Status: {String.capitalize(@status_filter)}
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M19 9l-7 7-7-7"
                    >
                    </path>
                  </svg>
                </div>
                <ul
                  tabindex="0"
                  class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow"
                >
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="all"
                      class={if @status_filter == "all", do: "active", else: ""}
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 12h6M9 16h6M9 8h6M3 12h18M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        >
                        </path>
                      </svg>
                      All Orders
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="pending"
                      class={if @status_filter == "pending", do: "active", else: ""}
                    >
                      <div class="badge badge-warning badge-sm"></div>
                      Pending
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="received"
                      class={if @status_filter == "received", do: "active", else: ""}
                    >
                      <div class="badge badge-info badge-sm"></div>
                      Received
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="assessed"
                      class={if @status_filter == "assessed", do: "active", else: ""}
                    >
                      <div class="badge badge-info badge-sm"></div>
                      Assessed
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="repairing"
                      class={if @status_filter == "repairing", do: "active", else: ""}
                    >
                      <div class="badge badge-primary badge-sm"></div>
                      Repairing
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="invoice_sent"
                      class={if @status_filter == "invoice_sent", do: "active", else: ""}
                    >
                      <div class="badge badge-warning badge-sm"></div>
                      Invoice Sent
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="paid"
                      class={if @status_filter == "paid", do: "active", else: ""}
                    >
                      <div class="badge badge-success badge-sm"></div>
                      Paid
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="shipping_back"
                      class={if @status_filter == "shipping_back", do: "active", else: ""}
                    >
                      <div class="badge badge-primary badge-sm"></div>
                      Shipping Back
                    </button>
                  </li>
                  <li>
                    <button
                      phx-click="filter_status"
                      phx-value-status="completed"
                      class={if @status_filter == "completed", do: "active", else: ""}
                    >
                      <div class="badge badge-success badge-sm"></div>
                      Completed
                    </button>
                  </li>
                </ul>
              </div>
              
    <!-- Search -->
              <.form for={%{}} as={:search} phx-submit="search" class="flex-1 max-w-md">
                <label class="input input-bordered flex items-center gap-2">
                  <input
                    name="search[query]"
                    value={@search_query}
                    placeholder="Search orders, customers..."
                    class="grow"
                  />
                  <button type="submit" class="btn btn-ghost btn-sm">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                      >
                      </path>
                    </svg>
                  </button>
                </label>
              </.form>
              
    <!-- Clear Filters -->
              <%= if @status_filter != "all" or @search_query != "" do %>
                <.link navigate={~p"/admin/orders"} class="btn btn-outline">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M6 18L18 6M6 6l12 12"
                    >
                    </path>
                  </svg>
                  Clear Filters
                </.link>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Orders Table -->
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Order #</th>
                    <th>Customer</th>
                    <th>Blind Details</th>
                    <th>Status</th>
                    <th>Amount</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= if length(@orders) == 0 do %>
                    <tr>
                      <td colspan="7" class="text-center py-12 text-base-content/60">
                        <div class="flex flex-col items-center">
                          <svg
                            class="w-16 h-16 mb-4 text-base-content/30"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M9 12h6M9 16h6M9 8h6M3 12h18M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                            />
                          </svg>
                          <%= if @search_query != "" or @status_filter != "all" do %>
                            <p class="text-lg font-medium mb-2">No orders found</p>
                            <p class="text-base-content/50">
                              Try adjusting your search or filter criteria.
                            </p>
                          <% else %>
                            <p class="text-lg font-medium mb-2">No orders yet</p>
                            <p class="text-base-content/50">
                              Orders will appear here once customers place them.
                            </p>
                          <% end %>
                        </div>
                      </td>
                    </tr>
                  <% else %>
                    <%= for order <- @orders do %>
                      <tr class="hover">
                        <td>
                          <.link
                            navigate={~p"/admin/orders/#{order.id}"}
                            class="link link-primary font-mono font-semibold"
                          >
                            #{String.pad_leading(to_string(order.id), 6, "0")}
                          </.link>
                        </td>
                        <td>
                          <div class="flex items-center gap-3">
                            <div class="avatar placeholder">
                              <div class="bg-neutral text-neutral-content w-8 rounded-full">
                                <span class="text-xs">
                                  {String.upcase(String.slice(order.user.first_name, 0, 1))}{String.upcase(
                                    String.slice(order.user.last_name, 0, 1)
                                  )}
                                </span>
                              </div>
                            </div>
                            <div>
                              <div class="font-medium">
                                {order.user.first_name} {order.user.last_name}
                              </div>
                              <div class="text-sm text-base-content/70">{order.user.email}</div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div class="text-sm">
                            <div class="font-medium">{format_order_items_summary(order)}</div>
                            <div class="text-base-content/70">
                              {get_total_items_quantity(order)} item(s)
                            </div>
                            <div class="badge badge-outline badge-sm mt-1">
                              {String.capitalize(order.service_level)} service
                            </div>
                          </div>
                        </td>
                        <td>
                          <div class="dropdown dropdown-end">
                            <div
                              tabindex="0"
                              role="button"
                              class={"badge cursor-pointer #{status_badge_class(order.status)}"}
                            >
                              {String.capitalize(order.status)}
                            </div>
                            <ul
                              tabindex="0"
                              class="dropdown-content menu bg-base-100 rounded-box z-[1] w-48 p-2 shadow"
                            >
                              <%= for status <- ["pending", "received", "assessed", "repairing", "invoice_sent", "paid", "shipping_back", "completed"] do %>
                                <%= if status != order.status do %>
                                  <li>
                                    <button
                                      phx-click="update_status"
                                      phx-value-id={order.id}
                                      phx-value-status={status}
                                      class="text-left"
                                    >
                                      Mark as {String.capitalize(String.replace(status, "_", " "))}
                                    </button>
                                  </li>
                                <% end %>
                              <% end %>
                            </ul>
                          </div>
                        </td>
                        <td class="font-mono font-semibold">${order.total_price}</td>
                        <td class="text-sm text-base-content/70">
                          {Calendar.strftime(order.inserted_at, "%b %d, %Y")}
                          <div class="text-xs text-base-content/50">
                            {Calendar.strftime(order.inserted_at, "%I:%M %p")}
                          </div>
                        </td>
                        <td>
                          <div class="flex gap-2">
                            <.link
                              navigate={~p"/admin/orders/#{order.id}"}
                              class="btn btn-sm btn-outline"
                            >
                              View
                            </.link>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp status_badge_class(status) do
    case status do
      "pending" -> "badge-warning"
      "received" -> "badge-info"
      "assessed" -> "badge-info"
      "repairing" -> "badge-primary"
      "invoice_sent" -> "badge-warning"
      "paid" -> "badge-success"
      "shipping_back" -> "badge-primary"
      "completed" -> "badge-success"
      "cancelled" -> "badge-error"
      _ -> "badge-ghost"
    end
  end

  defp format_order_items_summary(order) do
    case order.order_line_items do
      [] ->
        "No items"

      [item] ->
        "#{format_blind_type(item.blind_type)} #{item.width}\"×#{item.height}\""

      items when length(items) <= 2 ->
        items
        |> Enum.map(&"#{format_blind_type(&1.blind_type)} #{&1.width}\"×#{&1.height}\"")
        |> Enum.join(", ")

      items ->
        first_item = items |> List.first()

        "#{format_blind_type(first_item.blind_type)} #{first_item.width}\"×#{first_item.height}\", +#{length(items) - 1} more"
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
