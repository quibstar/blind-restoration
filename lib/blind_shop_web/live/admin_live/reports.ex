defmodule BlindShopWeb.AdminLive.Reports do
  use BlindShopWeb, :live_view

  alias BlindShop.Orders
  alias BlindShop.Accounts
  alias BlindShop.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:period, "30")
     |> assign(:selected_metric, "revenue")
     |> load_reports_data()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    period = Map.get(params, "period", "30")
    metric = Map.get(params, "metric", "revenue")

    {:noreply,
     socket
     |> assign(:period, period)
     |> assign(:selected_metric, metric)
     |> load_reports_data()}
  end

  @impl true
  def handle_event("change_period", %{"period" => period}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/reports?period=#{period}&metric=#{socket.assigns.selected_metric}"
     )}
  end

  @impl true
  def handle_event("change_metric", %{"metric" => metric}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/reports?period=#{socket.assigns.period}&metric=#{metric}"
     )}
  end

  defp load_reports_data(socket) do
    period_days = String.to_integer(socket.assigns.period)
    start_date = DateTime.utc_now() |> DateTime.add(-period_days, :day)

    # Order statistics
    total_orders = Repo.aggregate(Orders.Order, :count)
    
    period_orders =
      Orders.Order
      |> where([o], o.inserted_at >= ^start_date)
      |> Repo.aggregate(:count)

    # Revenue statistics
    total_revenue =
      Orders.Order
      |> where([o], o.status in ["completed", "shipped", "processing"])
      |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)

    period_revenue =
      Orders.Order
      |> where([o], o.status in ["completed", "shipped", "processing"])
      |> where([o], o.inserted_at >= ^start_date)
      |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)

    # Customer statistics
    total_customers = Repo.aggregate(Accounts.User, :count)
    
    new_customers =
      Accounts.User
      |> where([u], u.inserted_at >= ^start_date)
      |> Repo.aggregate(:count)

    # Status breakdown
    status_breakdown =
      Orders.Order
      |> where([o], o.inserted_at >= ^start_date)
      |> group_by([o], o.status)
      |> select([o], {o.status, count(o.id)})
      |> Repo.all()
      |> Enum.into(%{})

    # Blind type popularity
    blind_type_stats =
      Orders.Order
      |> where([o], o.inserted_at >= ^start_date)
      |> group_by([o], o.blind_type)
      |> select([o], {o.blind_type, count(o.id), sum(o.total_price)})
      |> Repo.all()
      |> Enum.map(fn {type, count, revenue} ->
        %{type: type, count: count, revenue: revenue || Decimal.new(0)}
      end)
      |> Enum.sort_by(& &1.count, :desc)

    # Service level breakdown
    service_level_stats =
      Orders.Order
      |> where([o], o.inserted_at >= ^start_date)
      |> group_by([o], o.service_level)
      |> select([o], {o.service_level, count(o.id), sum(o.total_price)})
      |> Repo.all()
      |> Enum.map(fn {level, count, revenue} ->
        %{level: level, count: count, revenue: revenue || Decimal.new(0)}
      end)

    # Top customers
    top_customers =
      Accounts.User
      |> join(:inner, [u], o in assoc(u, :orders))
      |> where([u, o], o.inserted_at >= ^start_date)
      |> group_by([u], [u.id, u.first_name, u.last_name, u.email])
      |> select([u, o], {u, count(o.id), sum(o.total_price)})
      |> order_by([u, o], desc: sum(o.total_price))
      |> limit(10)
      |> Repo.all()
      |> Enum.map(fn {user, order_count, total_spent} ->
        Map.merge(user, %{
          period_orders: order_count,
          period_spent: total_spent || Decimal.new(0)
        })
      end)

    # Recent activity (last 7 days for daily breakdown)
    recent_activity =
      0..6
      |> Enum.map(fn days_ago ->
        date = DateTime.utc_now() |> DateTime.add(-days_ago, :day)
        start_of_day = %{date | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
        end_of_day = %{date | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}

        orders_count =
          Orders.Order
          |> where([o], o.inserted_at >= ^start_of_day and o.inserted_at <= ^end_of_day)
          |> Repo.aggregate(:count)

        revenue =
          Orders.Order
          |> where([o], o.status in ["completed", "shipped", "processing"])
          |> where([o], o.inserted_at >= ^start_of_day and o.inserted_at <= ^end_of_day)
          |> Repo.aggregate(:sum, :total_price) || Decimal.new(0)

        %{
          date: date,
          orders: orders_count,
          revenue: revenue
        }
      end)
      |> Enum.reverse()

    socket
    |> assign(:total_orders, total_orders)
    |> assign(:period_orders, period_orders)
    |> assign(:total_revenue, total_revenue)
    |> assign(:period_revenue, period_revenue)
    |> assign(:total_customers, total_customers)
    |> assign(:new_customers, new_customers)
    |> assign(:status_breakdown, status_breakdown)
    |> assign(:blind_type_stats, blind_type_stats)
    |> assign(:service_level_stats, service_level_stats)
    |> assign(:top_customers, top_customers)
    |> assign(:recent_activity, recent_activity)
    |> assign(:start_date, start_date)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">Business Reports</h1>
          <p class="text-base-content/70 mt-2">Analytics and performance insights</p>
        </div>

        <!-- Period Selector -->
        <div class="card bg-base-100 shadow mb-6">
          <div class="card-body">
            <div class="flex flex-col sm:flex-row gap-4 items-center">
              <h3 class="text-lg font-semibold">Time Period:</h3>
              <div class="btn-group">
                <button
                  phx-click="change_period"
                  phx-value-period="7"
                  class={if @period == "7", do: "btn btn-primary", else: "btn btn-outline"}
                >
                  Last 7 days
                </button>
                <button
                  phx-click="change_period"
                  phx-value-period="30"
                  class={if @period == "30", do: "btn btn-primary", else: "btn btn-outline"}
                >
                  Last 30 days
                </button>
                <button
                  phx-click="change_period"
                  phx-value-period="90"
                  class={if @period == "90", do: "btn btn-primary", else: "btn btn-outline"}
                >
                  Last 90 days
                </button>
                <button
                  phx-click="change_period"
                  phx-value-period="365"
                  class={if @period == "365", do: "btn btn-primary", else: "btn btn-outline"}
                >
                  Last year
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Key Metrics -->
        <div class="stats stats-vertical lg:stats-horizontal shadow w-full mb-8">
          <div class="stat bg-base-100">
            <div class="stat-figure text-primary">
              <.icon name="hero-clipboard-document-list" class="w-8 h-8" />
            </div>
            <div class="stat-title">Orders ({@period} days)</div>
            <div class="stat-value text-primary">{@period_orders}</div>
            <div class="stat-desc">Total all time: {@total_orders}</div>
          </div>

          <div class="stat bg-base-100">
            <div class="stat-figure text-success">
              <.icon name="hero-currency-dollar" class="w-8 h-8" />
            </div>
            <div class="stat-title">Revenue ({@period} days)</div>
            <div class="stat-value text-success">${@period_revenue}</div>
            <div class="stat-desc">Total all time: ${@total_revenue}</div>
          </div>

          <div class="stat bg-base-100">
            <div class="stat-figure text-info">
              <.icon name="hero-user-group" class="w-8 h-8" />
            </div>
            <div class="stat-title">New Customers ({@period} days)</div>
            <div class="stat-value text-info">{@new_customers}</div>
            <div class="stat-desc">Total customers: {@total_customers}</div>
          </div>

          <div class="stat bg-base-100">
            <div class="stat-figure text-warning">
              <.icon name="hero-trending-up" class="w-8 h-8" />
            </div>
            <div class="stat-title">Avg Order Value</div>
            <div class="stat-value text-warning">
              $<%= if @period_orders > 0 do %>
                {Decimal.div(@period_revenue, @period_orders) |> Decimal.round(2)}
              <% else %>
                0
              <% end %>
            </div>
            <div class="stat-desc">Last {@period} days</div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <!-- Order Status Breakdown -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-chart-bar" class="w-6 h-6" />
                Order Status (Last {@period} days)
              </h2>
              <div class="space-y-3">
                <div class="flex justify-between items-center">
                  <div class="flex items-center gap-2">
                    <div class="badge badge-warning"></div>
                    <span>Pending</span>
                  </div>
                  <div class="font-semibold">{Map.get(@status_breakdown, "pending", 0)}</div>
                </div>
                <div class="flex justify-between items-center">
                  <div class="flex items-center gap-2">
                    <div class="badge badge-info"></div>
                    <span>Processing</span>
                  </div>
                  <div class="font-semibold">{Map.get(@status_breakdown, "processing", 0)}</div>
                </div>
                <div class="flex justify-between items-center">
                  <div class="flex items-center gap-2">
                    <div class="badge badge-primary"></div>
                    <span>Shipped</span>
                  </div>
                  <div class="font-semibold">{Map.get(@status_breakdown, "shipped", 0)}</div>
                </div>
                <div class="flex justify-between items-center">
                  <div class="flex items-center gap-2">
                    <div class="badge badge-success"></div>
                    <span>Completed</span>
                  </div>
                  <div class="font-semibold">{Map.get(@status_breakdown, "completed", 0)}</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Blind Type Popularity -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-funnel" class="w-6 h-6" />
                Blind Types (Last {@period} days)
              </h2>
              <div class="space-y-3">
                <%= for %{type: type, count: count, revenue: revenue} <- @blind_type_stats do %>
                  <div class="flex justify-between items-center">
                    <div>
                      <div class="font-medium">{String.capitalize(type)}</div>
                      <div class="text-sm text-base-content/70">${revenue}</div>
                    </div>
                    <div class="text-right">
                      <div class="font-semibold">{count}</div>
                      <div class="text-sm text-base-content/70">orders</div>
                    </div>
                  </div>
                <% end %>
                <%= if length(@blind_type_stats) == 0 do %>
                  <div class="text-center text-base-content/60 py-4">
                    No orders in this period
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <!-- Service Level Performance -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-bolt" class="w-6 h-6" />
                Service Levels (Last {@period} days)
              </h2>
              <div class="space-y-3">
                <%= for %{level: level, count: count, revenue: revenue} <- @service_level_stats do %>
                  <div class="flex justify-between items-center">
                    <div>
                      <div class="font-medium">{String.capitalize(level)}</div>
                      <div class="text-sm text-base-content/70">${revenue}</div>
                    </div>
                    <div class="text-right">
                      <div class="font-semibold">{count}</div>
                      <div class="text-sm text-base-content/70">orders</div>
                    </div>
                  </div>
                <% end %>
                <%= if length(@service_level_stats) == 0 do %>
                  <div class="text-center text-base-content/60 py-4">
                    No orders in this period
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Top Customers -->
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-user-group" class="w-6 h-6" />
                Top Customers (Last {@period} days)
              </h2>
              <div class="space-y-3">
                <%= for customer <- Enum.take(@top_customers, 5) do %>
                  <div class="flex items-center gap-3">
                    <div class="avatar placeholder">
                      <div class="bg-neutral text-neutral-content w-8 rounded-full">
                        <span class="text-xs">
                          {String.upcase(String.slice(customer.first_name, 0, 1))}{String.upcase(
                            String.slice(customer.last_name, 0, 1)
                          )}
                        </span>
                      </div>
                    </div>
                    <div class="flex-1">
                      <div class="font-medium text-sm">
                        {customer.first_name} {customer.last_name}
                      </div>
                      <div class="text-xs text-base-content/70">{customer.email}</div>
                    </div>
                    <div class="text-right">
                      <div class="font-semibold text-sm">${customer.period_spent}</div>
                      <div class="text-xs text-base-content/70">{customer.period_orders} orders</div>
                    </div>
                  </div>
                <% end %>
                <%= if length(@top_customers) == 0 do %>
                  <div class="text-center text-base-content/60 py-4">
                    No customer activity in this period
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Activity Chart -->
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-chart-bar" class="w-6 h-6" />
              Daily Activity (Last 7 days)
            </h2>
            <div class="overflow-x-auto">
              <table class="table table-zebra table-sm">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Orders</th>
                    <th>Revenue</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for day <- @recent_activity do %>
                    <tr>
                      <td class="font-medium">
                        {Calendar.strftime(day.date, "%a, %b %d")}
                      </td>
                      <td>
                        <div class="flex items-center gap-2">
                          <span class="font-semibold">{day.orders}</span>
                          <%= if day.orders > 0 do %>
                            <div class="badge badge-success badge-sm">+{day.orders}</div>
                          <% end %>
                        </div>
                      </td>
                      <td class="font-mono">${day.revenue}</td>
                    </tr>
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
end