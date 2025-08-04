defmodule BlindShopWeb.AdminLive.Dashboard do
  use BlindShopWeb, :live_view

  alias BlindShop.Orders
  alias BlindShop.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to order updates for real-time dashboard
      Phoenix.PubSub.subscribe(BlindShop.PubSub, "admin:dashboard")
    end

    {:ok, load_dashboard_data(socket)}
  end

  @impl true
  def handle_info({:order_updated, _order}, socket) do
    {:noreply, load_dashboard_data(socket)}
  end

  defp load_dashboard_data(socket) do
    # Get key metrics
    orders_query = from(o in Orders.Order)

    total_orders = Repo.aggregate(orders_query, :count)

    pending_orders =
      orders_query
      |> where([o], o.status == "pending")
      |> Repo.aggregate(:count)

    processing_orders =
      orders_query
      |> where([o], o.status == "processing")
      |> Repo.aggregate(:count)

    shipped_orders =
      orders_query
      |> where([o], o.status == "shipped")
      |> Repo.aggregate(:count)

    completed_orders =
      orders_query
      |> where([o], o.status == "completed")
      |> Repo.aggregate(:count)

    # Revenue calculations
    total_revenue =
      orders_query
      |> where([o], o.status in ["completed", "shipped", "processing"])
      |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)

    monthly_revenue =
      orders_query
      |> where([o], o.status in ["completed", "shipped", "processing"])
      |> where([o], o.inserted_at >= ^beginning_of_month())
      |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)

    # Recent orders
    recent_orders =
      orders_query
      |> order_by([o], desc: o.inserted_at)
      |> limit(10)
      |> Repo.all()
      |> Repo.preload(:user)

    # Orders needing attention (pending > 3 days)
    three_days_ago = DateTime.utc_now() |> DateTime.add(-3, :day)

    overdue_orders =
      orders_query
      |> where([o], o.status == "pending")
      |> where([o], o.inserted_at < ^three_days_ago)
      |> Repo.all()
      |> Repo.preload(:user)

    socket
    |> assign(:total_orders, total_orders)
    |> assign(:pending_orders, pending_orders)
    |> assign(:processing_orders, processing_orders)
    |> assign(:shipped_orders, shipped_orders)
    |> assign(:completed_orders, completed_orders)
    |> assign(:total_revenue, total_revenue)
    |> assign(:monthly_revenue, monthly_revenue)
    |> assign(:recent_orders, recent_orders)
    |> assign(:overdue_orders, overdue_orders)
  end

  defp beginning_of_month do
    now = DateTime.utc_now()
    %{now | day: 1, hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">Dashboard Overview</h1>
          <p class="text-base-content/70 mt-2">Monitor your blind repair business performance</p>
        </div>
        
    <!-- Key Metrics with DaisyUI Stats -->
        <div class="stats stats-vertical lg:stats-horizontal shadow w-full mb-8">
          <div class="stat bg-base-100">
            <div class="stat-figure text-primary">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12h6M9 16h6M9 8h6M3 12h18M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Total Orders</div>
            <div class="stat-value text-primary">{@total_orders}</div>
            <div class="stat-desc">All time</div>
          </div>

          <div class="stat bg-base-100">
            <div class="stat-figure text-warning">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Pending Orders</div>
            <div class="stat-value text-warning">{@pending_orders}</div>
            <div class="stat-desc">Awaiting shipment</div>
          </div>

          <div class="stat bg-base-100">
            <div class="stat-figure text-info">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                >
                </path>
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Processing</div>
            <div class="stat-value text-info">{@processing_orders}</div>
            <div class="stat-desc">In repair</div>
          </div>

          <div class="stat bg-base-100">
            <div class="stat-figure text-success">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Revenue (Month)</div>
            <div class="stat-value text-success">${@monthly_revenue}</div>
            <div class="stat-desc">Total: ${@total_revenue}</div>
          </div>
        </div>
        
    <!-- Action Items -->
        <%= if length(@overdue_orders) > 0 do %>
          <div role="alert" class="alert alert-warning mb-8">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6 shrink-0 stroke-current"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5C3.312 17.333 4.274 19 5.814 19z"
              />
            </svg>
            <div>
              <h3 class="font-bold">Orders Need Attention!</h3>
              <div class="text-xs">
                <strong>{length(@overdue_orders)} orders</strong>
                are pending for more than 3 days and need immediate action.
              </div>
            </div>
            <div>
              <.link navigate={~p"/admin/orders?status=pending"} class="btn btn-sm btn-warning">
                View Pending Orders
              </.link>
            </div>
          </div>
        <% end %>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Recent Orders -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-6 h-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12h6M9 16h6M9 8h6M3 12h18M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                Recent Orders
              </h2>
              <div class="overflow-x-auto">
                <table class="table table-zebra table-sm">
                  <thead>
                    <tr>
                      <th>Order #</th>
                      <th>Customer</th>
                      <th>Status</th>
                      <th>Amount</th>
                      <th>Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= if length(@recent_orders) == 0 do %>
                      <tr>
                        <td colspan="5" class="text-center py-8 text-base-content/60">
                          <div class="flex flex-col items-center">
                            <svg
                              class="w-12 h-12 mb-4 text-base-content/30"
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
                            <p>No orders yet</p>
                          </div>
                        </td>
                      </tr>
                    <% else %>
                      <%= for order <- @recent_orders do %>
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
                            <div class={"badge #{status_badge_class(order.status)}"}>
                              {String.capitalize(order.status)}
                            </div>
                          </td>
                          <td class="font-mono font-semibold">${order.total_price}</td>
                          <td class="text-sm text-base-content/70">
                            {Calendar.strftime(order.inserted_at, "%b %d")}
                          </td>
                        </tr>
                      <% end %>
                    <% end %>
                  </tbody>
                </table>
              </div>
              <div class="card-actions justify-end">
                <.link navigate={~p"/admin/orders"} class="btn btn-primary btn-sm">
                  View All Orders
                </.link>
              </div>
            </div>
          </div>
          
    <!-- Orders Needing Attention -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-warning">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-6 h-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5C3.312 17.333 4.274 19 5.814 19z"
                  />
                </svg>
                Orders Needing Attention
              </h2>
              <%= if length(@overdue_orders) == 0 do %>
                <div class="text-center py-8 text-base-content/60">
                  <div class="flex flex-col items-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-16 w-16 mx-auto mb-4 text-success"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    <p class="text-lg font-medium text-success">All caught up!</p>
                    <p class="text-base-content/70">No orders need immediate attention.</p>
                  </div>
                </div>
              <% else %>
                <div class="overflow-x-auto">
                  <table class="table table-zebra table-sm">
                    <thead>
                      <tr>
                        <th>Order #</th>
                        <th>Customer</th>
                        <th>Days Pending</th>
                        <th>Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for order <- @overdue_orders do %>
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
                                <div class="bg-warning text-warning-content w-8 rounded-full">
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
                            <div class="badge badge-warning gap-2">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="w-3 h-3"
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
                              {DateTime.diff(DateTime.utc_now(), order.inserted_at, :day)} days
                            </div>
                          </td>
                          <td class="font-mono font-semibold">${order.total_price}</td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Quick Actions -->
        <div class="mt-8">
          <h3 class="text-lg font-semibold mb-4">Quick Actions</h3>
          <div class="flex flex-wrap gap-4">
            <.link navigate={~p"/admin/orders"} class="btn btn-primary">
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
                  d="M9 12h6M9 16h6M9 8h6M3 12h18M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 002 2z"
                />
              </svg>
              Manage Orders
            </.link>

            <.link navigate={~p"/admin/customers"} class="btn btn-outline">
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
                  d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"
                />
              </svg>
              View Customers
            </.link>

            <.link navigate={~p"/admin/reports"} class="btn btn-outline">
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
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              Reports
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp status_badge_class(status) do
    case status do
      "pending" -> "badge-warning"
      "processing" -> "badge-info"
      "shipped" -> "badge-primary"
      "completed" -> "badge-success"
      "cancelled" -> "badge-error"
      _ -> "badge-ghost"
    end
  end
end
