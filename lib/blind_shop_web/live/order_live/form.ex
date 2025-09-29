defmodule BlindShopWeb.OrderLive.Form do
  use BlindShopWeb, :live_view

  alias BlindShop.Orders
  alias BlindShop.Orders.{Order, OrderLineItem}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto p-6">
        <.header>
          {@page_title}
          <:subtitle>
            <%= if @live_action == :new do %>
              Create your repair order - payment after repair completion
            <% else %>
              Update order details
            <% end %>
          </:subtitle>
        </.header>

        <div class="card bg-base-100 shadow-xl mt-8">
          <div class="card-body">
            <.form for={@form} id="order-form" phx-change="validate" phx-submit="save">
              
    <!-- Order Line Items Section -->
              <div class="space-y-6">
                <div class="flex justify-between items-center">
                  <h3 class="text-lg font-semibold">Blind Repair Items</h3>
                  <!-- Add Item Button using DockYard pattern -->
                  <label class="btn btn-outline btn-sm">
                    <input type="checkbox" name="order[order_line_items_sort][]" class="hidden" />
                    + Add Another Blind
                  </label>
                </div>
                
    <!-- Line Items -->
                <div class="space-y-4">
                  <.inputs_for :let={item_form} field={@form[:order_line_items]}>
                    <div class="border border-base-300 rounded-lg p-6 space-y-4 relative">
                      <!-- Remove Item Button - only show if more than one item -->
                      <%= if length(@form[:order_line_items].value || []) > 1 do %>
                        <label class="btn btn-xs btn-error absolute top-2 right-2">
                          <input
                            type="checkbox"
                            name="order[order_line_items_drop][]"
                            value={item_form.index}
                            class="hidden"
                          /> ×
                        </label>
                      <% end %>

                      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <!-- Blind Type -->
                        <.input
                          field={item_form[:blind_type]}
                          type="select"
                          label="Blind Type"
                          options={[
                            {"Mini Blinds", "mini"},
                            {"Vertical Blinds", "vertical"},
                            {"Honeycomb/Cellular", "honeycomb"},
                            {"Wood/Faux Wood", "wood"},
                            {"Roman Shades", "roman"}
                          ]}
                          prompt="Select blind type"
                        />
                        
    <!-- Dimensions -->
                        <.input
                          field={item_form[:width]}
                          type="number"
                          label="Width (inches)"
                          min="12"
                          max="144"
                          placeholder="e.g. 36"
                        />
                        <.input
                          field={item_form[:height]}
                          type="number"
                          label="Height (inches)"
                          min="12"
                          max="144"
                          placeholder="e.g. 48"
                        />
                      </div>

                      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <!-- Quantity -->
                        <.input
                          field={item_form[:quantity]}
                          type="number"
                          label="Quantity"
                          min="1"
                          max="50"
                          value="1"
                        />
                        
    <!-- Cord Color -->
                        <.input
                          field={item_form[:cord_color]}
                          type="select"
                          label="Cord Color"
                          options={[
                            {"White", "white"},
                            {"Beige/Cream", "beige"},
                            {"Tan", "tan"},
                            {"Brown", "brown"},
                            {"Black", "black"},
                            {"Gray", "gray"}
                          ]}
                          prompt="Select color"
                        />
                        
    <!-- Line Total (calculated) -->
                        <div class="form-control">
                          <label class="label">
                            <span class="label-text">Line Total</span>
                          </label>
                          <div class="bg-base-200 px-3 py-2 rounded font-semibold text-primary">
                            ${format_decimal(get_line_total(item_form, @form))}
                          </div>
                        </div>
                      </div>
                      
    <!-- Hidden calculated fields -->
                      <input
                        type="hidden"
                        name={"order[order_line_items][#{item_form.index}][base_price]"}
                        value={calculate_hidden_base_price(item_form)}
                      />
                      <input
                        type="hidden"
                        name={"order[order_line_items][#{item_form.index}][size_multiplier]"}
                        value={calculate_hidden_size_multiplier(item_form)}
                      />
                      <input
                        type="hidden"
                        name={"order[order_line_items][#{item_form.index}][surcharge]"}
                        value={calculate_hidden_surcharge(item_form)}
                      />
                      <input
                        type="hidden"
                        name={"order[order_line_items][#{item_form.index}][line_total]"}
                        value={calculate_hidden_line_total(item_form)}
                      />
                      <input
                        type="hidden"
                        name={"order[order_line_items][#{item_form.index}][line_order]"}
                        value={item_form.index}
                      />
                      <input
                        type="hidden"
                        name={"order[order_line_items][#{item_form.index}][temp_id]"}
                        value={
                          get_form_value(item_form, :temp_id)
                          |> then(fn val ->
                            if val == nil or val == "", do: generate_temp_id(), else: val
                          end)
                        }
                      />
                    </div>
                  </.inputs_for>
                  
    <!-- Message when no items -->
                  <%= if Enum.empty?(@form[:order_line_items].value || []) do %>
                    <div class="text-center py-8 text-base-content/60">
                      <p>No items added yet. Click "+ Add Another Blind" to get started.</p>
                    </div>
                  <% end %>
                </div>
              </div>
              
    <!-- Order-Level Settings -->
              <div class="divider"></div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Service Level for entire order -->
                <div>
                  <h4 class="font-semibold mb-3">Service Level</h4>
                  <.input
                    field={@form[:service_level]}
                    type="select"
                    label="Service Level"
                    options={[
                      {"Standard (10 days)", "standard"},
                      {"Rush (7 days) +25%", "rush"},
                      {"Priority (3 days) +50%", "priority"},
                      {"Express (2 days) +75%", "express"}
                    ]}
                  />
                </div>
                
    <!-- Return Address -->
                <div>
                  <h4 class="font-semibold mb-3">Return Address</h4>
                  <div class="space-y-3">
                    <.input
                      field={@form[:return_address_line1]}
                      type="text"
                      label="Address Line 1 *"
                      required
                    />
                    <.input
                      field={@form[:return_address_line2]}
                      type="text"
                      label="Address Line 2 (optional)"
                    />
                    <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
                      <.input field={@form[:return_city]} type="text" label="City *" required />
                      <.input field={@form[:return_state]} type="text" label="State *" required />
                      <.input field={@form[:return_zip]} type="text" label="ZIP Code *" required />
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Order Summary -->
              <div class="divider"></div>
              <div class="bg-base-200 p-4 rounded-lg space-y-2">
                <h4 class="font-semibold">Order Summary</h4>

                <%= for item_form <- @form[:order_line_items].value || [] do %>
                  <%= if has_valid_data(item_form) do %>
                    <div class="flex justify-between text-sm">
                      <span>
                        {format_blind_description(item_form, @form)}
                        <% cord_color = get_changeset_value(item_form, :cord_color) %>
                        <%= if cord_color != "" do %>
                          <span class="badge badge-xs badge-outline ml-1">
                            {String.capitalize(cord_color)}
                          </span>
                        <% end %>
                      </span>
                      <span>${format_decimal(get_line_total(item_form, @form))}</span>
                    </div>
                  <% end %>
                <% end %>

                <div class="divider my-2"></div>
                <div class="flex justify-between text-lg font-bold">
                  <span>Total Price:</span>
                  <span class="text-primary">
                    ${format_decimal(calculate_from_line_items(@form))}
                  </span>
                </div>
              </div>
              
    <!-- Notes -->
              <div class="mt-6">
                <.input
                  field={@form[:notes]}
                  type="textarea"
                  label="Special Instructions (optional)"
                  placeholder="Any specific repair instructions or concerns..."
                />
              </div>
              
    <!-- Terms of Service Agreement -->
              <div class="mt-6 p-4 bg-warning/10 border border-warning/20 rounded-lg">
                <div class="flex gap-4">
                  <input
                    type="checkbox"
                    name="terms_agreement"
                    class="checkbox checkbox-primary flex-shrink-0 mt-1"
                    required
                  />
                  <span class="label-text text-sm leading-relaxed ">
                    By placing this order, I confirm that I am sending my blinds at my own risk.
                    I understand that BlindRestoration.com is not responsible for any damage caused during shipping. I acknowledge that if my blinds are determined to be unrepairable, I may choose to have them returned or recycled at my discretion. I agree to the <.link
                      navigate={~p"/terms-of-service"}
                      target="_blank"
                      class="link link-primary"
                    >
                        Terms of Service
                      </.link>.
                  </span>
                </div>
              </div>
              
    <!-- Hidden fields -->
              <input
                type="hidden"
                name="order[total_price]"
                value={Decimal.to_string(calculate_from_line_items(@form))}
              />
              <input type="hidden" name="order[status]" value="pending" />
              <input type="hidden" name="order[volume_discount]" value="0.00" />

              <footer class="mt-8 flex gap-4">
                <%= if @live_action == :new do %>
                  <.button phx-disable-with="Creating Order..." class="btn btn-primary">
                    Create Order
                  </.button>
                <% else %>
                  <.button phx-disable-with="Updating Order..." class="btn btn-primary">
                    Update Order
                  </.button>
                <% end %>
                <.button navigate={~p"/dashboard"} class="btn btn-outline">
                  Cancel
                </.button>
              </footer>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    order = Orders.get_order!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Order")
    |> assign(:order, order)
    |> assign(:form, to_form(Orders.change_order(socket.assigns.current_scope, order)))
  end

  defp apply_action(socket, :new, _params) do
    # Start with empty order and one default line item with default values
    order = %Order{
      user_id: socket.assigns.current_scope.user.id,
      total_price: Decimal.new("0"),
      volume_discount: Decimal.new("0"),
      service_level: "standard",
      return_address_line1: "",
      return_city: "",
      return_state: "",
      return_zip: "",
      order_line_items: [
        %OrderLineItem{
          temp_id: generate_temp_id(),
          quantity: 1,
          line_order: 0,
          blind_type: "mini",
          width: 0,
          height: 0,
          cord_color: "white",
          base_price: Decimal.new("0"),
          size_multiplier: Decimal.new("1.0"),
          surcharge: Decimal.new("0"),
          line_total: Decimal.new("0")
        }
      ]
    }

    socket
    |> assign(:page_title, "New Order")
    |> assign(:order, order)
    |> assign(:form, to_form(Orders.change_order(socket.assigns.current_scope, order)))
  end

  @impl true
  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset =
      Orders.change_order(socket.assigns.current_scope, socket.assigns.order, order_params)

    form = to_form(changeset, action: :validate)

    # Trigger form update to recalculate totals
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"order" => order_params}, socket) do
    save_order(socket, socket.assigns.live_action, order_params)
  end

  # Helper functions for form calculations
  defp calculate_item_base_total(item) do
    # Handle different item structures
    blind_type = get_item_value(item, :blind_type)
    width = parse_int(get_item_value(item, :width))
    height = parse_int(get_item_value(item, :height))
    quantity = parse_int(get_item_value(item, :quantity))

    if blind_type != "" and width > 0 and height > 0 and quantity > 0 do
      calculate_line_item_base_total(blind_type, width, height, quantity)
    else
      Decimal.new("0")
    end
  end

  defp get_item_value(item, field) do
    cond do
      # Handle struct (OrderLineItem)
      is_struct(item) -> Map.get(item, field) |> to_string_safe()
      # Handle map with string keys
      is_map(item) and Map.has_key?(item, to_string(field)) -> item[to_string(field)] || ""
      # Handle map with atom keys
      is_map(item) and Map.has_key?(item, field) -> Map.get(item, field) |> to_string_safe()
      # Default
      true -> ""
    end
  end

  defp to_string_safe(value) do
    case value do
      val when is_binary(val) -> val
      val when is_integer(val) -> to_string(val)
      val when not is_nil(val) -> to_string(val)
      _ -> ""
    end
  end

  defp parse_int(value) do
    case value do
      val when is_integer(val) ->
        val

      val when is_binary(val) ->
        case Integer.parse(val) do
          {int_val, ""} -> int_val
          _ -> 0
        end

      _ ->
        0
    end
  end

  defp get_base_line_total(item_form) do
    # Extract values with better defaults
    blind_type = get_form_value(item_form, :blind_type)
    width = get_form_value(item_form, :width)
    height = get_form_value(item_form, :height)
    quantity = get_form_value(item_form, :quantity)
    quantity = if quantity == nil or quantity == "", do: "1", else: quantity

    with true <- is_binary(blind_type) and blind_type != "",
         true <- is_binary(width) and width != "",
         true <- is_binary(height) and height != "",
         true <- is_binary(quantity) and quantity != "",
         {width_int, ""} <- Integer.parse(width),
         {height_int, ""} <- Integer.parse(height),
         {quantity_int, ""} <- Integer.parse(quantity),
         true <- width_int > 0 and height_int > 0 and quantity_int > 0 do
      # Calculate base line total (without service level - that's applied at order level)
      calculate_line_item_base_total(blind_type, width_int, height_int, quantity_int)
    else
      _ -> Decimal.new("0")
    end
  end

  defp get_line_total(item, order_form) do
    # Simple access to service level
    service_level = order_form[:service_level].value || "standard"

    # Calculate base total for this item
    base_total = simple_line_total(item)

    # Apply service level for display
    service_multiplier =
      case service_level do
        "rush" -> Decimal.new("1.25")
        "priority" -> Decimal.new("1.5")
        "express" -> Decimal.new("1.75")
        _ -> Decimal.new("1.0")
      end

    Decimal.mult(base_total, service_multiplier)
  end

  defp calculate_line_item_base_total(blind_type, width, height, quantity) do
    # Base prices by blind type
    base_prices = %{
      "mini" => Decimal.new("55"),
      "vertical" => Decimal.new("70"),
      "honeycomb" => Decimal.new("85"),
      "wood" => Decimal.new("95"),
      "roman" => Decimal.new("110")
    }

    base_price = base_prices[blind_type] || Decimal.new("55")
    sqft = width * height / 144.0

    # Size multiplier
    size_multiplier =
      cond do
        sqft <= 15 -> Decimal.new("1.0")
        sqft <= 25 -> Decimal.new("1.2")
        sqft <= 35 -> Decimal.new("1.4")
        sqft <= 50 -> Decimal.new("1.7")
        sqft <= 70 -> Decimal.new("2.0")
        true -> Decimal.new("2.5")
      end

    # Surcharges
    surcharge =
      cond do
        width > 72 && height > 84 -> Decimal.new("40")
        width > 72 -> Decimal.new("25")
        height > 84 -> Decimal.new("20")
        true -> Decimal.new("0")
      end

    # Calculate base total (without service level - applied at order level)
    quantity_decimal = Decimal.new(quantity)

    subtotal =
      base_price
      |> Decimal.mult(size_multiplier)
      |> Decimal.add(surcharge)
      |> Decimal.mult(quantity_decimal)

    Decimal.round(subtotal, 2)
  end

  defp calculate_from_line_items(form) do
    # Simple direct access to form values
    line_items = form[:order_line_items].value || []
    service_level = form[:service_level].value || "standard"
    volume_discount = Decimal.new(form[:volume_discount].value || "0")

    # Calculate service multiplier
    service_multiplier =
      case service_level do
        "rush" -> Decimal.new("1.25")
        "priority" -> Decimal.new("1.5")
        "express" -> Decimal.new("1.75")
        _ -> Decimal.new("1.0")
      end

    # Calculate base line items total
    line_items_total =
      Enum.reduce(line_items, Decimal.new("0"), fn item, acc ->
        base_total = simple_line_total(item)
        Decimal.add(acc, base_total)
      end)

    # Apply service multiplier and subtract discount
    subtotal = Decimal.mult(line_items_total, service_multiplier)
    Decimal.sub(subtotal, volume_discount)
  end

  defp simple_line_total(item) do
    # Handle Ecto.Changeset - get values from changeset
    blind_type = get_changeset_value(item, :blind_type)
    width = parse_int(get_changeset_value(item, :width))
    height = parse_int(get_changeset_value(item, :height))
    quantity = parse_int(get_changeset_value(item, :quantity))

    if blind_type != "" and width > 0 and height > 0 and quantity > 0 do
      calculate_line_item_base_total(blind_type, width, height, quantity)
    else
      Decimal.new("0")
    end
  end

  defp get_changeset_value(item_form, field) do
    # Handle Phoenix.HTML.Form from inputs_for
    cond do
      # Phoenix.HTML.Form - check the form field first
      is_map(item_form) and Map.has_key?(item_form, field) ->
        case Map.get(item_form, field) do
          %Phoenix.HTML.FormField{value: value} when value != "" and not is_nil(value) ->
            to_string(value)

          _ ->
            # Try params and data as backup
            get_form_backup_value(item_form, field)
        end

      # No direct field access, try backup methods
      true ->
        get_form_backup_value(item_form, field)
    end
  end

  defp get_form_backup_value(item_form, field) do
    cond do
      # Try params from form
      is_map(item_form) and Map.has_key?(item_form, :params) ->
        case Map.get(item_form.params, to_string(field)) do
          value when value != "" and not is_nil(value) -> to_string(value)
          _ -> try_form_data(item_form, field)
        end

      # Try data from form
      true ->
        try_form_data(item_form, field)
    end
  end

  defp try_form_data(item_form, field) do
    case item_form do
      %{data: data} when is_struct(data) ->
        case Map.get(data, field) do
          value when value != "" and not is_nil(value) -> to_string(value)
          _ -> get_default_value(field)
        end

      _ ->
        get_default_value(field)
    end
  end

  defp get_form_value(form_field, field) do
    case form_field do
      # Handle Phoenix.HTML.Form struct
      %Phoenix.HTML.Form{} = form ->
        case form.params[to_string(field)] do
          value when is_binary(value) and value != "" ->
            value

          value when is_integer(value) ->
            to_string(value)

          _ ->
            case form.data do
              %{^field => value} when not is_nil(value) -> to_string(value)
              _ -> get_default_value(field)
            end
        end

      # Handle OrderLineItem struct
      %OrderLineItem{} = item ->
        case Map.get(item, field) do
          value when not is_nil(value) -> to_string(value)
          _ -> get_default_value(field)
        end

      # Handle form map from inputs_for
      form_map when is_map(form_map) ->
        # Try field as atom first
        case Map.get(form_map, field) do
          %{value: value} when value != "" and not is_nil(value) ->
            to_string(value)

          value when is_binary(value) and value != "" ->
            value

          value when not is_nil(value) ->
            to_string(value)

          _ ->
            # Try field as string
            case Map.get(form_map, to_string(field)) do
              value when is_binary(value) and value != "" -> value
              value when not is_nil(value) -> to_string(value)
              _ -> get_default_value(field)
            end
        end

      _ ->
        get_default_value(field)
    end
  end

  defp get_default_value(field) do
    case field do
      :quantity -> "1"
      :width -> "0"
      :height -> "0"
      :service_level -> "standard"
      :cord_color -> "white"
      :blind_type -> "mini"
      _ -> ""
    end
  end

  defp has_valid_data(item) do
    blind_type = get_changeset_value(item, :blind_type)
    width = get_changeset_value(item, :width)
    height = get_changeset_value(item, :height)

    blind_type != "" and width != "0" and height != "0"
  end

  defp format_blind_description(item, order_form) do
    blind_type = get_changeset_value(item, :blind_type)
    width = get_changeset_value(item, :width)
    height = get_changeset_value(item, :height)
    quantity = get_changeset_value(item, :quantity)
    service = order_form[:service_level].value || "standard"

    if blind_type != "" and width != "0" and height != "0" do
      type_name =
        case blind_type do
          "mini" -> "Mini Blind"
          "vertical" -> "Vertical Blind"
          "honeycomb" -> "Honeycomb Shade"
          "wood" -> "Wood Blind"
          "roman" -> "Roman Shade"
          _ -> String.capitalize(blind_type)
        end

      service_suffix = if service != "standard", do: " (#{String.capitalize(service)})", else: ""

      "#{quantity}x #{type_name} #{width}\"×#{height}\"#{service_suffix}"
    else
      "Incomplete item"
    end
  end

  defp format_decimal(decimal) do
    case decimal do
      %Decimal{} -> Decimal.to_string(Decimal.round(decimal, 2))
      value when is_binary(value) -> value
      _ -> "0.00"
    end
  end

  defp generate_temp_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16()
  end

  defp save_order(socket, :edit, order_params) do
    case Orders.update_order(socket.assigns.current_scope, socket.assigns.order, order_params) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, order)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> dbg
         |> put_flash(:error, "Please fix the errors below")}
    end
  end

  defp save_order(socket, :new, order_params) do
    # For new orders, create order immediately with unpaid status
    order_params = Map.put(order_params, "payment_status", "unpaid")

    case Orders.create_order(socket.assigns.current_scope, order_params) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Order created successfully! Please ship your blinds using the provided instructions."
         )
         |> push_navigate(to: ~p"/orders/#{order}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> dbg
         |> put_flash(:error, "Please fix the errors below")}
    end
  end

  defp return_path(_scope, "index", _order), do: ~p"/orders"
  defp return_path(_scope, "show", order), do: ~p"/orders/#{order}"

  # Helper functions for hidden field calculations
  defp calculate_hidden_base_price(item_form) do
    blind_type = get_changeset_value(item_form, :blind_type)

    base_prices = %{
      "mini" => "55",
      "vertical" => "70",
      "honeycomb" => "85",
      "wood" => "95",
      "roman" => "110"
    }

    base_prices[blind_type] || "55"
  end

  defp calculate_hidden_size_multiplier(item_form) do
    width = get_changeset_value(item_form, :width)
    height = get_changeset_value(item_form, :height)

    with {width_int, ""} <- Integer.parse(width),
         {height_int, ""} <- Integer.parse(height),
         true <- width_int > 0 and height_int > 0 do
      sqft = width_int * height_int / 144.0

      cond do
        sqft <= 15 -> "1.0"
        sqft <= 25 -> "1.2"
        sqft <= 35 -> "1.4"
        sqft <= 50 -> "1.7"
        sqft <= 70 -> "2.0"
        true -> "2.5"
      end
    else
      _ -> "1.0"
    end
  end

  defp calculate_hidden_surcharge(item_form) do
    width = get_changeset_value(item_form, :width)
    height = get_changeset_value(item_form, :height)

    with {width_int, ""} <- Integer.parse(width),
         {height_int, ""} <- Integer.parse(height) do
      cond do
        width_int > 72 && height_int > 84 -> "40"
        width_int > 72 -> "25"
        height_int > 84 -> "20"
        true -> "0"
      end
    else
      _ -> "0"
    end
  end

  defp calculate_hidden_line_total(item_form) do
    blind_type = get_changeset_value(item_form, :blind_type)
    width = parse_int(get_changeset_value(item_form, :width))
    height = parse_int(get_changeset_value(item_form, :height))
    quantity = parse_int(get_changeset_value(item_form, :quantity))

    if blind_type != "" and width > 0 and height > 0 and quantity > 0 do
      total = calculate_line_item_base_total(blind_type, width, height, quantity)
      Decimal.to_string(total)
    else
      "0"
    end
  end
end
