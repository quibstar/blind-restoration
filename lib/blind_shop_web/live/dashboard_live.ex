defmodule BlindShopWeb.DashboardLive do
  use BlindShopWeb, :live_view

  alias BlindShop.Orders
  alias BlindShop.Repo

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if connected?(socket) do
      # Set up periodic refresh every 30 seconds
      :timer.send_interval(30_000, self(), :refresh_orders)
    end

    {:ok, load_user_data(socket)}
  end

  @impl true
  def handle_info(:refresh_orders, socket) do
    # Periodically refresh orders from database
    {:noreply, load_user_data(socket)}
  end

  defp load_user_data(socket) do
    user = socket.assigns.current_scope.user

    # Get user's orders
    orders = Orders.list_orders(socket.assigns.current_scope)

    # Calculate statistics
    total_orders = length(orders)
    active_orders = Enum.count(orders, &(&1.status in ["pending", "received", "assessed", "repairing", "invoice_sent", "paid", "shipping_back"]))
    completed_orders = Enum.count(orders, &(&1.status == "completed"))

    total_spent =
      orders
      |> Enum.filter(&(&1.status != "cancelled"))
      |> Enum.reduce(Decimal.new(0), fn order, acc ->
        Decimal.add(acc, order.total_price)
      end)

    socket
    |> assign(:user, user)
    |> assign(:orders, orders)
    |> assign(:total_orders, total_orders)
    |> assign(:active_orders, active_orders)
    |> assign(:completed_orders, completed_orders)
    |> assign(:total_spent, total_spent)
  end


  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-7xl py-8 px-4 sm:px-6 lg:px-8">
        <!-- Welcome Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">
            Welcome back, {@current_scope.user.first_name}!
          </h1>
          <p class="text-base-content/70 mt-2">
            Manage your blind repair orders and track their progress
          </p>
        </div>
        
    <!-- Stats Overview -->
        <div class="stats stats-vertical bg-base-100 lg:stats-horizontal shadow w-full mb-8">
          <div class="stat">
            <div class="stat-figure text-primary">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Total Orders</div>
            <div class="stat-value text-primary">{@total_orders}</div>
            <div class="stat-desc">Lifetime orders placed</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-warning">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Active Orders</div>
            <div class="stat-value text-warning">{@active_orders}</div>
            <div class="stat-desc">Currently in progress</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-success">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Completed</div>
            <div class="stat-value text-success">{@completed_orders}</div>
            <div class="stat-desc">Successfully repaired</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-secondary">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Total Spent</div>
            <div class="stat-value text-secondary">${@total_spent}</div>
            <div class="stat-desc">Lifetime value</div>
          </div>
        </div>
        
    <!-- Quick Actions -->
        <div class="mb-8">
          <h2 class="text-xl font-semibold mb-4">Quick Actions</h2>
          <div class="flex flex-wrap gap-4">
            <.link navigate={~p"/#quote-calculator"} class="btn btn-primary">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                />
              </svg>
              Get Quote
            </.link>
            <.link navigate={~p"/orders/new"} class="btn btn-outline">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              Manual Order
            </.link>
            <.link navigate={~p"/shipping-instructions"} class="btn btn-outline">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Shipping Guide
            </.link>
            <a href="mailto:support@blindrestoration.com" class="btn btn-outline">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
              Contact Support
            </a>
          </div>
        </div>
        
    <!-- Orders Table -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
              Your Orders
            </h2>

            <%= if @orders == [] do %>
              <div class="text-center py-12">
                <svg
                  class="mx-auto h-12 w-12 text-base-content/30"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                  />
                </svg>
                <h3 class="mt-2 text-sm font-medium text-base-content">No orders yet</h3>
                <p class="mt-1 text-sm text-base-content/60">
                  Get started by creating your first order.
                </p>
                <div class="mt-6">
                  <.link navigate={~p"/"} class="btn btn-primary btn-sm">
                    Get a Quote
                  </.link>
                </div>
              </div>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Order #</th>
                      <th>Date</th>
                      <th>Blind Type</th>
                      <th>Quantity</th>
                      <th>Status</th>
                      <th>Total</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for order <- @orders do %>
                      <tr class="hover">
                        <td>
                          <.link
                            navigate={~p"/orders/#{order}"}
                            class="link link-primary font-mono font-semibold"
                          >
                            #{String.pad_leading(to_string(order.id), 6, "0")}
                          </.link>
                        </td>
                        <td class="text-sm">
                          {Calendar.strftime(order.inserted_at, "%b %d, %Y")}
                        </td>
                        <td class="text-sm">
                          <%= format_order_items(order) %>
                        </td>
                        <td>
                          <%= get_total_quantity(order) %>
                        </td>
                        <td>
                          <div class={"badge #{status_badge_class(order.status)} gap-2"}>
                            <%= if order.status == "pending" do %>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-3 w-3"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                                />
                              </svg>
                            <% end %>
                            <%= if order.status == "processing" do %>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-3 w-3 animate-spin"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                                />
                              </svg>
                            <% end %>
                            <%= if order.status == "shipped" do %>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-3 w-3"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z" />
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0"
                                />
                              </svg>
                            <% end %>
                            <%= if order.status == "completed" do %>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-3 w-3"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M5 13l4 4L19 7"
                                />
                              </svg>
                            <% end %>
                            {String.capitalize(order.status)}
                          </div>
                          <%= if order.status == "pending" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Awaiting shipment to us
                            </div>
                          <% end %>
                          <%= if order.status == "received" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Received at our facility
                            </div>
                          <% end %>
                          <%= if order.status == "assessed" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Assessment completed
                            </div>
                          <% end %>
                          <%= if order.status == "repairing" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Currently being repaired
                            </div>
                          <% end %>
                          <%= if order.status == "invoice_sent" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Ready for payment & return
                            </div>
                          <% end %>
                          <%= if order.status == "paid" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Payment received, preparing to ship
                            </div>
                          <% end %>
                          <%= if order.status == "shipping_back" do %>
                            <div class="text-xs text-base-content/60 mt-1">
                              Shipping back to you
                            </div>
                          <% end %>
                          <%= if order.tracking_number do %>
                            <div class="text-xs mt-1">
                              <span class="text-base-content/60">
                                <%= if order.carrier, do: "#{String.upcase(order.carrier)} ", else: "" %>Tracking:
                              </span>
                              <%= if order.carrier do %>
                                <a href={get_tracking_url(order.carrier, order.tracking_number)} 
                                   target="_blank" 
                                   class="font-mono link link-primary">
                                  {order.tracking_number}
                                </a>
                              <% else %>
                                <span class="font-mono">{order.tracking_number}</span>
                              <% end %>
                            </div>
                          <% end %>
                        </td>
                        <td class="font-mono font-semibold">
                          ${order.total_price}
                        </td>
                        <td>
                          <div class="flex gap-2">
                            <.link navigate={~p"/orders/#{order}"} class="btn btn-ghost btn-xs">
                              View
                            </.link>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Help Section -->
        <div class="mt-8 card bg-info/10 border border-info/20">
          <div class="card-body">
            <h3 class="card-title text-info">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Need Help?
            </h3>
            <p>
              Check out our
              <.link navigate={~p"/shipping-instructions"} class="link link-info">
                shipping instructions
              </.link>
              or <a href="mailto:support@blindrestoration.com" class="link link-info">contact support</a>
              if you have any questions.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
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

  defp format_order_items(order) do
    case order.order_line_items do
      [] -> "No items"
      [item] -> 
        "#{format_blind_type(item.blind_type)}"
      items when length(items) <= 3 ->
        items
        |> Enum.map(&format_blind_type(&1.blind_type))
        |> Enum.join(", ")
      items ->
        first_two = items |> Enum.take(2) |> Enum.map(&format_blind_type(&1.blind_type)) |> Enum.join(", ")
        "#{first_two}, +#{length(items) - 2} more"
    end
  end

  defp get_total_quantity(order) do
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

  # Generate tracking URL for different carriers
  defp get_tracking_url(carrier, tracking_number) when is_binary(carrier) and is_binary(tracking_number) do
    case String.downcase(carrier) do
      "ups" -> "https://www.ups.com/track?track=yes&trackNums=#{tracking_number}"
      "fedex" -> "https://www.fedex.com/fedextrack/?trknbr=#{tracking_number}"
      "usps" -> "https://tools.usps.com/go/TrackConfirmAction?tLabels=#{tracking_number}"
      "dhl" -> "https://www.dhl.com/us-en/home/tracking.html?tracking-id=#{tracking_number}"
      _ -> "https://www.google.com/search?q=track+package+#{tracking_number}"
    end
  end
  defp get_tracking_url(_, _), do: ""
end
