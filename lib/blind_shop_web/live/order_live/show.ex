defmodule BlindShopWeb.OrderLive.Show do
  use BlindShopWeb, :live_view

  alias BlindShop.Orders
  alias BlindShop.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto p-6">
        <.header>
          Order #{String.pad_leading(to_string(@order.id), 6, "0")}
          <:subtitle>
            Created {Calendar.strftime(@order.inserted_at, "%B %d, %Y at %I:%M %p")}
          </:subtitle>
          <:actions>
            <%= if @order.status == "pending" do %>
              <.link navigate={~p"/orders/#{@order}/edit"} class="btn btn-sm btn-outline">
                <.icon name="hero-pencil" class="h-4 w-4" /> Edit
              </.link>
            <% end %>
            <.link navigate={~p"/orders"} class="btn btn-sm btn-ghost">
              Back to Orders
            </.link>
          </:actions>
        </.header>
        
    <!-- Status Card -->
        <div class="card bg-base-100 shadow-xl mt-8">
          <div class="card-body">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold">Order Status</h3>
              <% {label, class} = Order.status_badge(@order.status) %>
              <span class={"badge badge-lg #{class}"}>{label}</span>
            </div>
            
    <!-- Status Timeline -->
            <ul class="steps steps-vertical lg:steps-horizontal w-full text-xs">
              <li class="step step-primary" data-content="✓">
                <div class="text-left">
                  <div class="font-semibold">Order Placed</div>
                  <div class="text-sm text-base-content/60">
                    {Calendar.strftime(@order.inserted_at, "%b %d")}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(received assessed repairing invoice_sent paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  cond do
                    @order.received_at -> "✓"
                    @order.status == "pending" -> "→"
                    true -> "2"
                  end
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Received</div>
                  <div class="text-sm text-base-content/60">
                    {if @order.received_at,
                      do: Calendar.strftime(@order.received_at, "%b %d"),
                      else: if(@order.status == "pending", do: "Shipping to us", else: "Pending")}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(assessed repairing invoice_sent paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  cond do
                    @order.assessed_at -> "✓"
                    @order.status == "received" -> "→"
                    true -> "3"
                  end
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Assessed</div>
                  <div class="text-sm text-base-content/60">
                    {if @order.assessed_at,
                      do: Calendar.strftime(@order.assessed_at, "%b %d"),
                      else: if(@order.status == "received", do: "Being assessed", else: "Pending")}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(repairing invoice_sent paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  cond do
                    @order.repair_completed_at -> "✓"
                    @order.status in ~w(assessed repairing) -> "→"
                    true -> "4"
                  end
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Repaired</div>
                  <div class="text-sm text-base-content/60">
                    {cond do
                      @order.repair_completed_at ->
                        Calendar.strftime(@order.repair_completed_at, "%b %d")

                      @order.status in ~w(assessed repairing) ->
                        "In progress"

                      true ->
                        "Pending"
                    end}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(invoice_sent paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  cond do
                    @order.paid_at -> "✓"
                    @order.status == "invoice_sent" -> "→"
                    true -> "5"
                  end
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Payment</div>
                  <div class="text-sm text-base-content/60">
                    {cond do
                      @order.paid_at -> Calendar.strftime(@order.paid_at, "%b %d")
                      @order.status == "invoice_sent" -> "Invoice sent"
                      @order.repair_completed_at -> "Payment due"
                      true -> "After repair"
                    end}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(shipping_back completed), do: "step-primary"}"}
                data-content={
                  cond do
                    @order.completed_at -> "✓"
                    @order.status == "shipping_back" -> "→"
                    true -> "6"
                  end
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Delivered</div>
                  <div class="text-sm text-base-content/60">
                    {cond do
                      @order.completed_at -> Calendar.strftime(@order.completed_at, "%b %d")
                      @order.status == "shipping_back" -> "Shipping back"
                      @order.paid_at -> "Preparing to ship"
                      true -> "After payment"
                    end}
                  </div>
                </div>
              </li>
            </ul>

            <%= if @order.tracking_number do %>
              <div class="alert alert-info mt-6">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  class="stroke-current shrink-0 w-6 h-6"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  >
                  </path>
                </svg>
                <div>
                  <h3 class="font-bold">Tracking Number</h3>
                  <div class="text-xs">{@order.tracking_number}</div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Order Details -->
        <div class="grid grid-cols-1 gap-6 mt-6">
          <!-- Order Line Items -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">Order Items</h3>

              <%= if Enum.any?(@order.order_line_items) do %>
                <div class="overflow-x-auto">
                  <table class="table table-zebra">
                    <thead>
                      <tr>
                        <th>Type</th>
                        <th>Dimensions</th>
                        <th>Quantity</th>
                        <th>Cord Color</th>
                        <th>Line Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for item <- @order.order_line_items do %>
                        <tr>
                          <td>
                            <span class="font-semibold">
                              {format_blind_type(item.blind_type)}
                            </span>
                          </td>
                          <td>{item.width}" × {item.height}"</td>
                          <td>{item.quantity}</td>
                          <td>
                            <%= if item.cord_color do %>
                              <span class="badge badge-outline">
                                {String.capitalize(item.cord_color)}
                              </span>
                            <% end %>
                          </td>
                          <td class="font-semibold">${item.line_total}</td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>

                <div class="divider"></div>
                
    <!-- Order Summary -->
                <div class="flex justify-between items-center">
                  <span class="text-base-content/70">Service Level:</span>
                  <span class="font-semibold capitalize">{@order.service_level}</span>
                </div>
              <% else %>
                <div class="text-center py-8 text-base-content/60">
                  <p>No items in this order.</p>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Pricing Summary -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">Pricing Summary</h3>
              <div class="space-y-2">
                <%= if Enum.any?(@order.order_line_items) do %>
                  <% subtotal = calculate_items_subtotal(@order.order_line_items) %>
                  <div class="flex justify-between">
                    <span class="text-base-content/70">Items Subtotal:</span>
                    <span>${subtotal}</span>
                  </div>

                  <%= if @order.service_level != "standard" do %>
                    <% service_multiplier = get_service_multiplier(@order.service_level) %>
                    <div class="flex justify-between">
                      <span class="text-base-content/70">
                        Service Level ({String.capitalize(@order.service_level)}):
                      </span>
                      <span>{service_multiplier}x</span>
                    </div>
                  <% end %>
                <% end %>
                <%= if Decimal.gt?(@order.volume_discount, Decimal.new("0")) do %>
                  <div class="flex justify-between text-success">
                    <span>Volume Discount:</span>
                    <span>-${@order.volume_discount}</span>
                  </div>
                <% end %>
                <div class="divider my-2"></div>
                <div class="flex justify-between text-lg font-bold">
                  <span>Total:</span>
                  <span class="text-primary">${@order.total_price}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Special Instructions -->
        <%= if @order.notes && @order.notes != "" do %>
          <div class="card bg-base-100 shadow-xl mt-6">
            <div class="card-body">
              <h3 class="card-title">Special Instructions</h3>
              <p class="whitespace-pre-wrap">{@order.notes}</p>
            </div>
          </div>
        <% end %>
        
    <!-- Actions -->
        <div class="card bg-base-100 shadow-xl mt-6">
          <div class="card-body">
            <h3 class="card-title">What's Next?</h3>
            <%= case @order.status do %>
              <% "pending" -> %>
                <p>Time to ship your blinds! Send them to our repair facility:</p>
                <div class="alert alert-info mt-4">
                  <div>
                    <h4 class="font-bold">Ship To:</h4>
                    <div class="mt-2">
                      <p class="font-semibold">Blind Restoration</p>
                      <p>11034 Island CT.</p>
                      <p>Allendale, MI 49401</p>
                    </div>
                    <div class="mt-3">
                      <p class="text-sm">
                        <strong>Reference:</strong>
                        Order #{String.pad_leading(to_string(@order.id), 6, "0")}
                      </p>
                      <p class="text-sm text-base-content/70">
                        Please include this order number on your package
                      </p>
                    </div>
                  </div>
                </div>
                <div class="card-actions justify-start mt-4">
                  <.link navigate={~p"/shipping-instructions"} class="btn btn-primary">
                    View Detailed Shipping Instructions
                  </.link>
                </div>
              <% "processing" -> %>
                <p>
                  We're working on your blinds! You'll receive an email when they're ready to ship back.
                </p>
              <% "shipped" -> %>
                <p>
                  Your blinds are on their way back to you! Track your package with the tracking number above.
                </p>
              <% "completed" -> %>
                <p>We hope you're enjoying your repaired blinds! Need another repair?</p>
                <div class="card-actions justify-start mt-4">
                  <.link navigate={~p"/"} class="btn btn-primary">
                    Get Another Quote
                  </.link>
                </div>
              <% _ -> %>
                <p>Contact support if you need assistance with this order.</p>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(socket.assigns.current_scope, id)

    if connected?(socket) do
      # Set up periodic refresh every 30 seconds
      :timer.send_interval(30_000, self(), :refresh_order)
    end

    {:ok,
     socket
     |> assign(:page_title, "Order ##{String.pad_leading(to_string(order.id), 6, "0")}")
     |> assign(:order, order)}
  end

  @impl true
  def handle_info(:refresh_order, socket) do
    # Periodically refresh order from database
    order = Orders.get_order!(socket.assigns.current_scope, socket.assigns.order.id)
    {:noreply, assign(socket, :order, order)}
  end

  # Helper functions
  defp format_blind_type(blind_type) do
    case blind_type do
      "mini" -> "Mini Blinds"
      "vertical" -> "Vertical Blinds"
      "honeycomb" -> "Honeycomb Shades"
      "wood" -> "Wood Blinds"
      "roman" -> "Roman Shades"
      _ -> String.capitalize(blind_type || "Unknown")
    end
  end

  defp calculate_items_subtotal(line_items) do
    Enum.reduce(line_items, Decimal.new("0"), fn item, acc ->
      Decimal.add(acc, item.line_total || Decimal.new("0"))
    end)
  end

  defp get_service_multiplier(service_level) do
    case service_level do
      "rush" -> "1.25"
      "priority" -> "1.5"
      "express" -> "1.75"
      _ -> "1.0"
    end
  end
end
