defmodule BlindShopWeb.AdminLive.InvoiceForm do
  use BlindShopWeb, :live_view

  alias BlindShop.Admin.Orders, as: AdminOrders
  alias BlindShop.Orders.InvoiceLineItem
  alias BlindShop.Payments.InvoiceService
  alias BlindShop.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <.header>
          Create Invoice for Order #<%= String.pad_leading(to_string(@order.id), 6, "0") %>
          <:subtitle>
            Customer: <%= @order.user.first_name %> <%= @order.user.last_name %> (<%= @order.user.email %>)
          </:subtitle>
          <:actions>
            <.link navigate={~p"/admin/orders/#{@order}"} class="btn btn-sm btn-ghost">
              Back to Order
            </.link>
          </:actions>
        </.header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-8">
          <!-- Invoice Form -->
          <div class="lg:col-span-2">
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h3 class="card-title">Invoice Details</h3>
                
                <.form for={@form} phx-change="validate" phx-submit="generate_invoice" class="space-y-6">
                  <!-- Line Items Section -->
                  <div>
                    <h4 class="text-lg font-semibold mb-4">Line Items</h4>
                    
                    <div class="space-y-4" id="line-items">
                      <%= for {line_item, index} <- Enum.with_index(@line_items) do %>
                        <div class="border border-base-300 rounded-lg p-4 relative" id={"line-item-#{index}"}>
                          <button 
                            type="button" 
                            phx-click="remove_line_item" 
                            phx-value-index={index}
                            class="absolute top-2 right-2 btn btn-xs btn-error btn-circle z-10"
                            title="Remove line item"
                          >
                            ×
                          </button>
                          
                          <div class="grid grid-cols-1 md:grid-cols-4 gap-4 pr-8">
                            <div class="md:col-span-2">
                              <input 
                                type="text" 
                                name={"line_items[#{index}][description]"}
                                value={line_item.description}
                                placeholder="e.g. Blind Repair Service, Replacement Cord"
                                class="input input-bordered w-full"
                                phx-blur="update_line_item"
                                phx-value-index={index}
                                phx-value-field="description"
                              />
                              <label class="label">
                                <span class="label-text">Description</span>
                              </label>
                            </div>
                            <div>
                              <input 
                                type="number" 
                                name={"line_items[#{index}][quantity]"}
                                value={line_item.quantity}
                                min="1"
                                step="1"
                                class="input input-bordered w-full"
                                phx-blur="update_line_item"
                                phx-value-index={index}
                                phx-value-field="quantity"
                              />
                              <label class="label">
                                <span class="label-text">Quantity</span>
                              </label>
                            </div>
                            <div>
                              <input 
                                type="number" 
                                name={"line_items[#{index}][unit_price]"}
                                value={Decimal.to_string(line_item.unit_price)}
                                min="0"
                                step="0.01"
                                placeholder="0.00"
                                class="input input-bordered w-full"
                                phx-blur="update_line_item"
                                phx-value-index={index}
                                phx-value-field="unit_price"
                              />
                              <label class="label">
                                <span class="label-text">Unit Price</span>
                              </label>
                            </div>
                          </div>
                          
                          <!-- Calculated Total -->
                          <div class="mt-2 text-right">
                            <span class="text-sm text-base-content/70">Total: </span>
                            <span class="font-semibold">
                              $<%= Decimal.to_string(calculate_line_total(line_item)) %>
                            </span>
                          </div>
                        </div>
                      <% end %>
                      
                      <button 
                        type="button" 
                        phx-click="add_line_item" 
                        class="btn btn-outline btn-sm w-full"
                      >
                        + Add Line Item
                      </button>
                    </div>
                  </div>

                  <!-- Shipping & Disposal Options -->
                  <div class="divider"></div>
                  
                  <div>
                    <h4 class="text-lg font-semibold mb-4">Shipping & Disposal</h4>
                    
                    <div class="form-control">
                      <label class="label cursor-pointer">
                        <span class="label-text">Blinds are returnable (in good condition)</span>
                        <input 
                          type="checkbox" 
                          class="checkbox" 
                          checked={@is_returnable}
                          phx-click="toggle_returnable"
                        />
                      </label>
                    </div>

                    <%= if @is_returnable do %>
                      <div class="form-control mt-4">
                        <input 
                          type="number" 
                          name="shipping_cost"
                          value={Decimal.to_string(@shipping_cost)}
                          min="0"
                          step="0.01"
                          placeholder="15.00"
                          class="input input-bordered"
                          phx-blur="update_shipping_cost"
                        />
                        <label class="label">
                          <span class="label-text">Return Shipping Cost</span>
                          <span class="label-text-alt">Cost to ship blinds back to customer</span>
                        </label>
                      </div>
                    <% else %>
                      <div class="form-control mt-4">
                        <textarea 
                          name="disposal_reason"
                          class="textarea textarea-bordered"
                          placeholder="Blinds were too damaged to return safely..."
                          phx-blur="update_disposal_reason"
                        ><%= @disposal_reason %></textarea>
                        <label class="label">
                          <span class="label-text">Disposal Reason</span>
                          <span class="label-text-alt">Explain why blinds cannot be returned</span>
                        </label>
                      </div>
                    <% end %>
                  </div>

                  <!-- Actions -->
                  <div class="card-actions justify-end pt-4">
                    <.link navigate={~p"/admin/orders/#{@order}"} class="btn btn-ghost">
                      Cancel
                    </.link>
                    <button type="submit" class="btn btn-success">
                      Generate Invoice & Send
                    </button>
                  </div>
                </.form>
              </div>
            </div>
          </div>

          <!-- Invoice Preview -->
          <div class="lg:col-span-1">
            <div class="card bg-base-100 shadow-xl sticky top-6">
              <div class="card-body">
                <h3 class="card-title">Invoice Preview</h3>
                
                <div class="space-y-2">
                  <div class="text-sm">
                    <strong>Order:</strong> #<%= String.pad_leading(to_string(@order.id), 6, "0") %>
                  </div>
                  <div class="text-sm">
                    <strong>Customer:</strong> <%= @order.user.first_name %> <%= @order.user.last_name %>
                  </div>
                  <div class="text-sm">
                    <strong>Email:</strong> <%= @order.user.email %>
                  </div>
                </div>

                <div class="divider"></div>

                <!-- Line Items Preview -->
                <div class="space-y-2">
                  <%= for line_item <- @line_items do %>
                    <%= if line_item.description && line_item.description != "" do %>
                      <div class="flex justify-between text-sm">
                        <span><%= line_item.description %></span>
                        <span>$<%= Decimal.to_string(calculate_line_total(line_item)) %></span>
                      </div>
                      <%= if line_item.quantity > 1 do %>
                        <div class="text-xs text-base-content/60 ml-2">
                          <%= line_item.quantity %> × $<%= Decimal.to_string(line_item.unit_price) %>
                        </div>
                      <% end %>
                    <% end %>
                  <% end %>

                  <!-- Shipping Cost Preview -->
                  <%= if @is_returnable && Decimal.gt?(@shipping_cost, Decimal.new("0")) do %>
                    <div class="flex justify-between text-sm">
                      <span>Return Shipping</span>
                      <span>$<%= Decimal.to_string(@shipping_cost) %></span>
                    </div>
                  <% end %>
                </div>

                <div class="divider"></div>

                <!-- Total Preview -->
                <div class="flex justify-between font-bold">
                  <span>Total Due:</span>
                  <span class="text-primary">$<%= Decimal.to_string(calculate_total(assigns)) %></span>
                </div>

                <%= if not @is_returnable do %>
                  <div class="text-info text-xs mt-2">
                    Blinds will be disposed of - no return shipping
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = AdminOrders.get_order!(id)
    
    # Initialize with default line items from order line items
    initial_line_items = 
      order.order_line_items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        %{
          description: "Blind Repair Service - #{format_blind_type(item.blind_type)} #{item.width}\"×#{item.height}\"",
          quantity: item.quantity,
          unit_price: Decimal.div(item.line_total, Decimal.new(item.quantity)),
          line_order: index
        }
      end)
    
    # Add shipping if applicable  
    initial_line_items = if order.shipping_cost && Decimal.gt?(order.shipping_cost, Decimal.new("0")) do
      initial_line_items ++ [%{
        description: "Return Shipping",
        quantity: 1,
        unit_price: order.shipping_cost,
        line_order: length(initial_line_items)
      }]
    else
      initial_line_items
    end

    {:ok,
     socket
     |> assign(:page_title, "Create Invoice - Order ##{String.pad_leading(to_string(order.id), 6, "0")}")
     |> assign(:order, order)
     |> assign(:line_items, initial_line_items)
     |> assign(:is_returnable, order.is_returnable)
     |> assign(:shipping_cost, order.shipping_cost || Decimal.new("15.00"))
     |> assign(:disposal_reason, order.disposal_reason || "")
     |> assign(:form, to_form(%{}))}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add_line_item", _params, socket) do
    new_line_item = %{
      description: "",
      quantity: 1,
      unit_price: Decimal.new("0.00"),
      line_order: length(socket.assigns.line_items)
    }
    
    updated_line_items = socket.assigns.line_items ++ [new_line_item]
    {:noreply, assign(socket, :line_items, updated_line_items)}
  end

  def handle_event("remove_line_item", %{"index" => index}, socket) do
    index = String.to_integer(index)
    updated_line_items = List.delete_at(socket.assigns.line_items, index)
    {:noreply, assign(socket, :line_items, updated_line_items)}
  end

  def handle_event("update_line_item", %{"index" => index, "field" => field, "value" => value}, socket) do
    index = String.to_integer(index)
    line_items = socket.assigns.line_items    
    
    updated_item = case field do
      "description" -> %{Enum.at(line_items, index) | description: value}
      "quantity" -> 
        quantity = case Integer.parse(value) do
          {q, ""} when q > 0 -> q
          _ -> 1
        end
        %{Enum.at(line_items, index) | quantity: quantity}
      "unit_price" ->
        unit_price = case Decimal.new(value) do
          %Decimal{} = price -> price
          _ -> Decimal.new("0.00")
        end
        %{Enum.at(line_items, index) | unit_price: unit_price}
    end
    
    updated_line_items = List.replace_at(line_items, index, updated_item)
    {:noreply, assign(socket, :line_items, updated_line_items)}
  end

  def handle_event("toggle_returnable", _params, socket) do
    {:noreply, assign(socket, :is_returnable, !socket.assigns.is_returnable)}
  end

  def handle_event("update_shipping_cost", %{"value" => value}, socket) do
    shipping_cost = case Decimal.new(value) do
      %Decimal{} = cost -> cost
      _ -> Decimal.new("0.00")
    end
    {:noreply, assign(socket, :shipping_cost, shipping_cost)}
  end

  def handle_event("update_disposal_reason", %{"value" => value}, socket) do
    {:noreply, assign(socket, :disposal_reason, value)}
  end

  def handle_event("generate_invoice", _params, socket) do
    order = socket.assigns.order
    line_items = socket.assigns.line_items
    
    # Update order attributes
    attrs = %{
      is_returnable: socket.assigns.is_returnable,
      shipping_cost: if(socket.assigns.is_returnable, do: socket.assigns.shipping_cost, else: Decimal.new("0")),
      disposal_reason: if(socket.assigns.is_returnable, do: nil, else: socket.assigns.disposal_reason)
    }
    
    case AdminOrders.update_order(order, attrs) do
      {:ok, updated_order} ->
        # Save line items to database
        case save_line_items(updated_order, line_items) do
          {:ok, _line_items} ->
            # Generate invoice with line items
            case InvoiceService.generate_invoice_with_line_items(updated_order) do
              {:ok, final_order} ->
                {:noreply,
                 socket
                 |> put_flash(:info, "Invoice generated and sent to customer")
                 |> redirect(to: ~p"/admin/orders/#{final_order}")}
              
              {:error, _error} ->
                {:noreply, put_flash(socket, :error, "Failed to generate invoice")}
            end
          
          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Failed to save line items")}
        end
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update order")}
    end
  end

  # Helper functions
  defp calculate_line_total(line_item) do
    Decimal.mult(Decimal.new(line_item.quantity), line_item.unit_price)
  end

  defp calculate_total(assigns) do
    line_items_total = assigns.line_items
    |> Enum.reduce(Decimal.new("0"), fn line_item, acc ->
      Decimal.add(acc, calculate_line_total(line_item))
    end)

    shipping_total = if assigns.is_returnable do
      assigns.shipping_cost
    else
      Decimal.new("0")
    end

    Decimal.add(line_items_total, shipping_total)
  end

  defp save_line_items(order, line_items) do
    # First, delete existing line items
    Repo.delete_all(Ecto.assoc(order, :invoice_line_items))
    
    # Then create new ones
    line_items
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {line_item, index}, {:ok, acc} ->
      attrs = %{
        order_id: order.id,
        description: line_item.description,
        quantity: line_item.quantity,
        unit_price: line_item.unit_price,
        total: calculate_line_total(line_item),
        line_order: index
      }
      
      case %InvoiceLineItem{} |> InvoiceLineItem.changeset(attrs) |> Repo.insert() do
        {:ok, saved_item} -> {:cont, {:ok, [saved_item | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp format_blind_type(blind_type) do
    case blind_type do
      "mini" -> "Mini Blinds"
      "vertical" -> "Vertical Blinds"
      "honeycomb" -> "Honeycomb/Cellular"
      "wood" -> "Wood/Faux Wood"
      "roman" -> "Roman Shades"
      _ -> String.capitalize(blind_type || "Unknown")
    end
  end
end