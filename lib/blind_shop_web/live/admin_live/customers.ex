defmodule BlindShopWeb.AdminLive.Customers do
  use BlindShopWeb, :live_view

  alias BlindShop.Accounts
  alias BlindShop.Orders
  alias BlindShop.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:search_query, "")
     |> assign(:sort_by, "inserted_at")
     |> assign(:sort_order, "desc")
     |> load_customers()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    search_query = Map.get(params, "search", "")
    sort_by = Map.get(params, "sort_by", "inserted_at")
    sort_order = Map.get(params, "sort_order", "desc")

    {:noreply,
     socket
     |> assign(:search_query, search_query)
     |> assign(:sort_by, sort_by)
     |> assign(:sort_order, sort_order)
     |> load_customers()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/admin/customers?search=#{query}&sort_by=#{socket.assigns.sort_by}&sort_order=#{socket.assigns.sort_order}"
     )}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    sort_order =
      if socket.assigns.sort_by == field and socket.assigns.sort_order == "asc" do
        "desc"
      else
        "asc"
      end

    {:noreply,
     push_patch(socket,
       to:
         ~p"/admin/customers?search=#{socket.assigns.search_query}&sort_by=#{field}&sort_order=#{sort_order}"
     )}
  end

  defp load_customers(socket) do
    customers =
      Accounts.User
      |> apply_search_filter(socket.assigns.search_query)
      |> apply_sorting(socket.assigns.sort_by, socket.assigns.sort_order)
      |> Repo.all()
      |> Repo.preload(orders: [:user])

    customers_with_stats =
      Enum.map(customers, fn customer ->
        order_count = length(customer.orders)

        total_spent =
          customer.orders
          |> Enum.map(& &1.total_price)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        last_order =
          customer.orders
          |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
          |> List.first()

        Map.merge(customer, %{
          order_count: order_count,
          total_spent: total_spent,
          last_order_date: if(last_order, do: last_order.inserted_at, else: nil)
        })
      end)

    assign(socket, :customers, customers_with_stats)
  end

  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search_query) do
    search_term = "%#{search_query}%"

    query
    |> where(
      [u],
      ilike(u.first_name, ^search_term) or
        ilike(u.last_name, ^search_term) or
        ilike(u.email, ^search_term)
    )
  end

  defp apply_sorting(query, "first_name", order) do
    case order do
      "asc" -> order_by(query, [u], asc: u.first_name)
      "desc" -> order_by(query, [u], desc: u.first_name)
    end
  end

  defp apply_sorting(query, "last_name", order) do
    case order do
      "asc" -> order_by(query, [u], asc: u.last_name)
      "desc" -> order_by(query, [u], desc: u.last_name)
    end
  end

  defp apply_sorting(query, "email", order) do
    case order do
      "asc" -> order_by(query, [u], asc: u.email)
      "desc" -> order_by(query, [u], desc: u.email)
    end
  end

  defp apply_sorting(query, "inserted_at", order) do
    case order do
      "asc" -> order_by(query, [u], asc: u.inserted_at)
      "desc" -> order_by(query, [u], desc: u.inserted_at)
    end
  end

  defp apply_sorting(query, _, _), do: order_by(query, [u], desc: u.inserted_at)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">Customer Management</h1>
          <p class="text-base-content/70 mt-2">View and manage customer information</p>
        </div>
        
    <!-- Stats Summary -->
        <div class="stats shadow mb-6 bg-base-100">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-user-group" class="w-8 h-8" />
            </div>
            <div class="stat-title">Total Customers</div>
            <div class="stat-value text-primary">{length(@customers)}</div>
            <div class="stat-desc">Registered users</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-success">
              <.icon name="hero-currency-dollar" class="w-8 h-8" />
            </div>
            <div class="stat-title">Active Customers</div>
            <div class="stat-value text-success">
              {Enum.count(@customers, fn c -> c.order_count > 0 end)}
            </div>
            <div class="stat-desc">Have placed orders</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-info">
              <.icon name="hero-trending-up" class="w-8 h-8" />
            </div>
            <div class="stat-title">Average Orders</div>
            <div class="stat-value text-info">
              {if length(@customers) > 0 do
                total_orders = @customers |> Enum.map(& &1.order_count) |> Enum.sum()
                (total_orders / length(@customers)) |> Float.round(1)
              else
                0
              end}
            </div>
            <div class="stat-desc">Per customer</div>
          </div>
        </div>
        
    <!-- Search and Filters -->
        <div class="card bg-base-100 shadow mb-6">
          <div class="card-body">
            <div class="flex flex-col sm:flex-row gap-4">
              <!-- Search -->
              <.form for={%{}} as={:search} phx-submit="search" class="flex-1 max-w-md">
                <label class="input input-bordered flex items-center gap-2">
                  <input
                    name="search[query]"
                    value={@search_query}
                    placeholder="Search customers..."
                    class="grow"
                  />
                  <button type="submit" class="btn btn-ghost btn-sm">
                    <.icon name="hero-magnifying-glass" class="w-4 h-4" />
                  </button>
                </label>
              </.form>
              
    <!-- Clear Search -->
              <%= if @search_query != "" do %>
                <.link navigate={~p"/admin/customers"} class="btn btn-outline">
                  <.icon name="hero-x-mark" class="w-4 h-4" /> Clear Search
                </.link>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Customers Table -->
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>
                      <button
                        phx-click="sort"
                        phx-value-field="first_name"
                        class="btn btn-ghost btn-sm flex items-center gap-1"
                      >
                        Customer {sort_icon(@sort_by, @sort_order, "first_name")}
                      </button>
                    </th>
                    <th>
                      <button
                        phx-click="sort"
                        phx-value-field="email"
                        class="btn btn-ghost btn-sm flex items-center gap-1"
                      >
                        Email {sort_icon(@sort_by, @sort_order, "email")}
                      </button>
                    </th>
                    <th>Orders</th>
                    <th>Total Spent</th>
                    <th>
                      <button
                        phx-click="sort"
                        phx-value-field="inserted_at"
                        class="btn btn-ghost btn-sm flex items-center gap-1"
                      >
                        Joined {sort_icon(@sort_by, @sort_order, "inserted_at")}
                      </button>
                    </th>
                    <th>Last Order</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= if length(@customers) == 0 do %>
                    <tr>
                      <td colspan="7" class="text-center py-12 text-base-content/60">
                        <div class="flex flex-col items-center">
                          <.icon name="hero-user-group" class="w-16 h-16 mb-4 text-base-content/30" />
                          <%= if @search_query != "" do %>
                            <p class="text-lg font-medium mb-2">No customers found</p>
                            <p class="text-base-content/50">Try adjusting your search criteria.</p>
                          <% else %>
                            <p class="text-lg font-medium mb-2">No customers yet</p>
                            <p class="text-base-content/50">
                              Customers will appear here when they register.
                            </p>
                          <% end %>
                        </div>
                      </td>
                    </tr>
                  <% else %>
                    <%= for customer <- @customers do %>
                      <tr class="hover">
                        <td>
                          <div class="flex items-center gap-3">
                            <div class="avatar placeholder">
                              <div class="bg-neutral text-neutral-content w-10 rounded-full">
                                <span class="text-sm">
                                  {String.upcase(String.slice(customer.first_name, 0, 1))}{String.upcase(
                                    String.slice(customer.last_name, 0, 1)
                                  )}
                                </span>
                              </div>
                            </div>
                            <div>
                              <div class="font-medium">
                                {customer.first_name} {customer.last_name}
                              </div>
                              <div class="text-sm text-base-content/70">
                                Customer #{String.pad_leading(to_string(customer.id), 6, "0")}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div class="text-sm">
                            <div class="font-medium">{customer.email}</div>
                            <div class="text-base-content/70">
                              <%= if customer.confirmed_at do %>
                                <div class="badge badge-success badge-sm">Verified</div>
                              <% else %>
                                <div class="badge badge-warning badge-sm">Unverified</div>
                              <% end %>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div class="text-center">
                            <div class="font-semibold text-lg">{customer.order_count}</div>
                            <div class="text-xs text-base-content/70">
                              <%= if customer.order_count > 0 do %>
                                orders
                              <% else %>
                                no orders
                              <% end %>
                            </div>
                          </div>
                        </td>
                        <td class="font-mono font-semibold">${customer.total_spent}</td>
                        <td class="text-sm text-base-content/70">
                          {Calendar.strftime(customer.inserted_at, "%b %d, %Y")}
                        </td>
                        <td class="text-sm text-base-content/70">
                          <%= if customer.last_order_date do %>
                            {Calendar.strftime(customer.last_order_date, "%b %d, %Y")}
                          <% else %>
                            <span class="text-base-content/50">Never</span>
                          <% end %>
                        </td>
                        <td>
                          <div class="flex gap-2">
                            <%= if customer.order_count > 0 do %>
                              <.link
                                navigate={~p"/admin/orders?search=#{customer.email}"}
                                class="btn btn-sm btn-outline"
                              >
                                View Orders
                              </.link>
                            <% else %>
                              <span class="text-base-content/50 text-sm">No actions</span>
                            <% end %>
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

  defp sort_icon(current_sort, current_order, field) do
    cond do
      current_sort == field and current_order == "asc" ->
        assigns = %{}

        ~H"""
        <.icon name="hero-chevron-up" class="w-4 h-4" />
        """

      current_sort == field and current_order == "desc" ->
        assigns = %{}

        ~H"""
        <.icon name="hero-chevron-down" class="w-4 h-4" />
        """

      true ->
        assigns = %{}

        ~H"""
        <.icon name="hero-chevron-up-down" class="w-4 h-4 opacity-30" />
        """
    end
  end
end
