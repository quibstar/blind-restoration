defmodule BlindShopWeb.AdminLive.OrderDetail do
  use BlindShopWeb, :live_view

  alias BlindShop.Admin.Orders, as: AdminOrders
  alias BlindShop.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto my-4">
        <.header>
          Order #{String.pad_leading(to_string(@order.id), 6, "0")}
          <:subtitle>
            Customer: {@order.user.first_name} {@order.user.last_name} ({@order.user.email})
          </:subtitle>
          <:actions>
            <.link navigate={~p"/admin/orders"} class="btn btn-sm btn-ghost">
              Back to Orders
            </.link>
          </:actions>
        </.header>
        
    <!-- Admin Actions Card -->
        <div class="card bg-base-100 shadow-xl mt-8">
          <div class="card-body">
            <h3 class="card-title">Admin Actions</h3>
            <div class="flex flex-wrap gap-3">
              <!-- Status Update Buttons -->
              <%= if @order.status == "pending" do %>
                <button
                  phx-click="update_status"
                  phx-value-status="received"
                  class="btn btn-sm btn-primary"
                >
                  Mark as Received
                </button>
              <% end %>

              <%= if @order.status == "received" do %>
                <button
                  phx-click="update_status"
                  phx-value-status="assessed"
                  class="btn btn-sm btn-primary"
                >
                  Complete Assessment
                </button>
              <% end %>

              <%= if @order.status == "assessed" do %>
                <button
                  phx-click="update_status"
                  phx-value-status="repairing"
                  class="btn btn-sm btn-primary"
                >
                  Start Repair
                </button>
              <% end %>

              <%= if @order.status == "repairing" do %>
                <.link navigate={~p"/admin/orders/#{@order}/invoice"} class="btn btn-sm btn-success">
                  Complete Repair & Send Invoice
                </.link>
              <% end %>

              <%= if @order.status == "paid" do %>
                <button
                  phx-click="update_status"
                  phx-value-status="shipping_back"
                  class="btn btn-sm btn-primary"
                >
                  Ship Back to Customer
                </button>
              <% end %>

              <%= if @order.status == "shipping_back" do %>
                <button
                  phx-click="update_status"
                  phx-value-status="completed"
                  class="btn btn-sm btn-success"
                >
                  Mark as Completed
                </button>
              <% end %>
              
    <!-- Universal Actions -->
              <button phx-click="add_notes" class="btn btn-sm btn-outline">
                Add Notes
              </button>

              <%= if @order.status not in ["cancelled", "completed"] do %>
                <button
                  phx-click="cancel_order"
                  class="btn btn-sm btn-error"
                  data-confirm="Are you sure you want to cancel this order?"
                >
                  Cancel Order
                </button>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Status Card -->
        <div class="card bg-base-100 shadow-xl mt-6">
          <div class="card-body">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold">Order Status</h3>
              <% {label, class} = Order.status_badge(@order.status) %>
              <span class={"badge badge-lg #{class}"}>{label}</span>
            </div>
            
    <!-- Status Timeline for New Workflow -->
            <ul class="steps steps-vertical lg:steps-horizontal w-full text-xs">
              <li class="step step-primary" data-content="✓">
                <div class="text-left">
                  <div class="font-semibold">Order Placed</div>
                  <div class="text-xs text-base-content/60">
                    {Calendar.strftime(@order.inserted_at, "%b %d")}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(received assessed repairing invoice_sent paid shipping_back completed), do: "step-primary"} #{if @order.status == "pending", do: "step-warning"}"}
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
                  <div class="text-xs text-base-content/60">
                    {if @order.received_at,
                      do: Calendar.strftime(@order.received_at, "%b %d"),
                      else: if(@order.status == "pending", do: "Next Step", else: "Pending")}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(assessed repairing invoice_sent paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  if @order.status == "assessed",
                    do: "→",
                    else: if(@order.assessed_at, do: "✓", else: "3")
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Assessed</div>
                  <div class="text-xs text-base-content/60">
                    {if @order.assessed_at,
                      do: Calendar.strftime(@order.assessed_at, "%b %d"),
                      else: "Pending"}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(repairing invoice_sent paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  if @order.status == "repairing",
                    do: "→",
                    else: if(@order.repair_completed_at, do: "✓", else: "4")
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Repaired</div>
                  <div class="text-xs text-base-content/60">
                    {if @order.repair_completed_at,
                      do: Calendar.strftime(@order.repair_completed_at, "%b %d"),
                      else: "Working"}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(paid shipping_back completed), do: "step-primary"}"}
                data-content={
                  if @order.status == "invoice_sent",
                    do: "5",
                    else: if(@order.paid_at, do: "✓", else: "5")
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Paid</div>
                  <div class="text-xs text-base-content/60">
                    {if @order.paid_at,
                      do: Calendar.strftime(@order.paid_at, "%b %d"),
                      else: "Awaiting"}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status in ~w(shipping_back completed), do: "step-primary"}"}
                data-content={
                  if @order.status == "shipping_back",
                    do: "6",
                    else: if(@order.shipped_at, do: "✓", else: "6")
                }
              >
                <div class="text-left">
                  <div class="font-semibold">Shipped Back</div>
                  <div class="text-xs text-base-content/60">
                    {if @order.shipped_at,
                      do: Calendar.strftime(@order.shipped_at, "%b %d"),
                      else: "Pending"}
                  </div>
                </div>
              </li>
              <li
                class={"step #{if @order.status == "completed", do: "step-primary"}"}
                data-content={if @order.status == "completed", do: "✓", else: "7"}
              >
                <div class="text-left">
                  <div class="font-semibold">Completed</div>
                  <div class="text-xs text-base-content/60">
                    {if @order.completed_at,
                      do: Calendar.strftime(@order.completed_at, "%b %d"),
                      else: "Pending"}
                  </div>
                </div>
              </li>
            </ul>
            
    <!-- Payment & Invoice Info -->
            <%= if @order.payment_status != "unpaid" do %>
              <div class="alert alert-info mt-4">
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
                  <h3 class="font-bold">
                    Payment Status: {format_payment_status(@order.payment_status)}
                  </h3>
                  <div class="text-xs">
                    {if @order.invoice_id, do: "Invoice ID: #{@order.invoice_id}"}
                    {if @order.payment_intent_id, do: "Payment ID: #{@order.payment_intent_id}"}
                  </div>
                </div>
              </div>
            <% end %>

            <%= if @order.tracking_number do %>
              <div class="alert alert-success mt-4">
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
                  <div class="text-xs font-mono">{@order.tracking_number}</div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Order Line Items -->
        <div class="card bg-base-100 shadow-xl mt-6">
          <div class="card-body">
            <h3 class="card-title">Order Items</h3>

            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Blind Type</th>
                    <th>Dimensions</th>
                    <th>Qty</th>
                    <th>Cord Color</th>
                    <th>Line Total</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- (@order.order_line_items || []) do %>
                    <tr>
                      <td>{format_blind_type(item.blind_type)}</td>
                      <td>{item.width}" × {item.height}"</td>
                      <td>{item.quantity}</td>
                      <td>
                        <%= if item.cord_color do %>
                          <span
                            class="badge badge-sm"
                            style={"background-color: #{cord_color_hex(item.cord_color)}; color: #{cord_color_text(item.cord_color)}"}
                          >
                            {String.capitalize(item.cord_color)}
                          </span>
                        <% else %>
                          <span class="text-base-content/50">Not specified</span>
                        <% end %>
                      </td>
                      <td class="font-semibold">${item.line_total}</td>
                    </tr>
                  <% end %>
                </tbody>
                <tfoot>
                  <tr class="font-bold">
                    <td colspan="4" class="text-right">Subtotal:</td>
                    <td>${calculate_subtotal(@order)}</td>
                  </tr>
                  <tr>
                    <td colspan="4" class="text-right">Service Level:</td>
                    <td>
                      <span class="badge badge-outline">
                        {String.capitalize(@order.service_level)}
                      </span>
                    </td>
                  </tr>
                  <%= if Decimal.gt?(@order.volume_discount || Decimal.new("0"), Decimal.new("0")) do %>
                    <tr class="text-success">
                      <td colspan="4" class="text-right">Volume Discount:</td>
                      <td>-${@order.volume_discount}</td>
                    </tr>
                  <% end %>
                  <tr class="font-bold text-lg">
                    <td colspan="4" class="text-right">Total:</td>
                    <td class="text-primary">${@order.total_price}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        </div>
        
    <!-- Customer Info -->
        <div class="card bg-base-100 shadow-xl mt-6">
          <div class="card-body">
            <h3 class="card-title">Customer Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <div class="text-sm text-base-content/70">Name</div>
                <div class="font-semibold">{@order.user.first_name} {@order.user.last_name}</div>
              </div>
              <div>
                <div class="text-sm text-base-content/70">Email</div>
                <div class="font-semibold">{@order.user.email}</div>
              </div>
              <div>
                <div class="text-sm text-base-content/70">Customer Since</div>
                <div class="font-semibold">
                  {Calendar.strftime(@order.user.inserted_at, "%B %d, %Y")}
                </div>
              </div>
              <div>
                <div class="text-sm text-base-content/70">Order Created</div>
                <div class="font-semibold">
                  {Calendar.strftime(@order.inserted_at, "%B %d, %Y at %I:%M %p")}
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Return Address -->
        <div class="card bg-base-100 shadow-xl mt-6">
          <div class="card-body">
            <h3 class="card-title">Return Address</h3>
            <div class="text-sm">
              {@order.return_address_line1}<br />
              <%= if @order.return_address_line2 do %>
                {@order.return_address_line2}<br />
              <% end %>
              {@order.return_city}, {@order.return_state} {@order.return_zip}
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
      </div>

      <!-- Notes Modal -->
      <%= if @show_notes_modal do %>
        <div class="modal modal-open">
          <div class="modal-box">
            <h3 class="font-bold text-lg">Order Notes</h3>
            <p class="py-2 text-sm text-base-content/70">
              Add or edit notes for Order #<%= String.pad_leading(to_string(@order.id), 6, "0") %>
            </p>
            
            <form phx-submit="save_notes">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Notes</span>
                </label>
                <textarea 
                  name="notes" 
                  class="textarea textarea-bordered h-32" 
                  placeholder="Enter notes about this order..."
                ><%= @order.notes || "" %></textarea>
              </div>
              
              <div class="modal-action">
                <button type="submit" class="btn btn-primary">Save Notes</button>
                <button type="button" class="btn" phx-click="close_notes_modal">Cancel</button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = AdminOrders.get_order!(id)

    {:ok,
     socket
     |> assign(:page_title, "Order ##{String.pad_leading(to_string(order.id), 6, "0")}")
     |> assign(:order, order)
     |> assign(:show_notes_modal, false)
     |> assign(:notes_form, to_form(%{"notes" => order.notes || ""}))}
  end

  @impl true
  def handle_event("update_status", %{"status" => new_status}, socket) do
    order = socket.assigns.order

    # Add timestamp for specific status changes
    attrs =
      case new_status do
        "received" -> %{status: new_status, received_at: DateTime.utc_now()}
        "assessed" -> %{status: new_status, assessed_at: DateTime.utc_now()}
        "shipping_back" -> %{status: new_status, shipped_at: DateTime.utc_now()}
        "completed" -> %{status: new_status, completed_at: DateTime.utc_now()}
        _ -> %{status: new_status}
      end

    case AdminOrders.update_order(order, attrs) do
      {:ok, updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order status updated to #{String.capitalize(new_status)}")
         |> assign(:order, updated_order)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update order status")}
    end
  end

  def handle_event("cancel_order", _params, socket) do
    order = socket.assigns.order

    case AdminOrders.cancel_order(order, "Cancelled by admin") do
      {:ok, updated_order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order cancelled")
         |> assign(:order, updated_order)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel order")}
    end
  end

  def handle_event("add_notes", _params, socket) do
    {:noreply, assign(socket, show_notes_modal: true)}
  end

  def handle_event("close_notes_modal", _params, socket) do
    {:noreply, assign(socket, show_notes_modal: false)}
  end

  def handle_event("save_notes", %{"notes" => notes}, socket) do
    order = socket.assigns.order

    case AdminOrders.update_order_notes(order, notes) do
      {:ok, updated_order} ->
        {:noreply,
         socket
         |> assign(:order, updated_order)
         |> assign(:show_notes_modal, false)
         |> put_flash(:info, "Notes updated successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update notes")}
    end
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  defp format_payment_status(status) do
    case status do
      "unpaid" -> "Awaiting Payment (Post-Repair)"
      "invoice_sent" -> "Invoice Sent - Awaiting Payment"
      "paid" -> "Payment Received"
      "failed" -> "Payment Failed"
      "refunded" -> "Payment Refunded"
      _ -> String.capitalize(String.replace(status, "_", " "))
    end
  end

  defp format_blind_type(blind_type) do
    case blind_type do
      "mini" -> "Mini Blinds"
      "vertical" -> "Vertical Blinds"
      "honeycomb" -> "Honeycomb/Cellular"
      "wood" -> "Wood/Faux Wood"
      "roman" -> "Roman Shades"
      _ -> String.capitalize(blind_type)
    end
  end

  defp calculate_subtotal(order) do
    (order.order_line_items || [])
    |> Enum.reduce(Decimal.new("0"), fn item, acc ->
      Decimal.add(acc, item.line_total || Decimal.new("0"))
    end)
  end

  defp cord_color_hex(color) do
    case color do
      "white" -> "#ffffff"
      "beige" -> "#f5f5dc"
      "tan" -> "#d2b48c"
      "brown" -> "#8b4513"
      "black" -> "#000000"
      "gray" -> "#808080"
      _ -> "#e5e7eb"
    end
  end

  defp cord_color_text(color) do
    case color do
      "white" -> "#000000"
      "beige" -> "#000000"
      "tan" -> "#000000"
      "brown" -> "#ffffff"
      "black" -> "#ffffff"
      "gray" -> "#ffffff"
      _ -> "#000000"
    end
  end
end
