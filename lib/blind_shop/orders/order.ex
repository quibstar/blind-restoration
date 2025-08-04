defmodule BlindShop.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlindShop.Orders.{InvoiceLineItem, OrderLineItem}

  schema "orders" do
    # Order-level fields
    field :service_level, :string, default: "standard"
    field :volume_discount, :decimal, default: Decimal.new("0")
    field :total_price, :decimal
    field :status, :string, default: "pending"
    field :tracking_number, :string
    field :shipping_label_url, :string
    field :notes, :string
    field :shipped_at, :utc_datetime
    field :completed_at, :utc_datetime
    
    # Payment fields
    field :checkout_session_id, :string
    field :payment_intent_id, :string
    field :payment_status, :string, default: "unpaid"
    field :paid_at, :utc_datetime
    
    # Repair workflow fields
    field :invoice_sent_at, :utc_datetime
    field :invoice_id, :string
    field :repair_completed_at, :utc_datetime
    field :received_at, :utc_datetime
    field :assessed_at, :utc_datetime
    
    # Shipping and disposal fields
    field :shipping_cost, :decimal, default: Decimal.new("0")
    field :is_returnable, :boolean, default: true
    field :disposal_reason, :string
    
    # Return address fields
    field :return_address_line1, :string
    field :return_address_line2, :string
    field :return_city, :string
    field :return_state, :string
    field :return_zip, :string
    
    # Order line items for multi-item orders
    has_many :order_line_items, OrderLineItem, preload_order: [:line_order], on_replace: :delete
    
    # Invoice line items for flexible billing
    has_many :invoice_line_items, InvoiceLineItem, preload_order: [:line_order]
    
    belongs_to :user, BlindShop.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(pending received assessed repairing invoice_sent paid shipping_back completed cancelled)
  @service_levels ~w(standard rush priority express)
  @payment_statuses ~w(unpaid invoice_sent paid failed refunded)

  @doc false
  def changeset(order, attrs) do
    changeset = 
      order
      |> cast(attrs, [:service_level, :volume_discount, :total_price, :status, :tracking_number, :shipping_label_url, 
                      :notes, :shipped_at, :completed_at, :user_id,
                      :checkout_session_id, :payment_intent_id, :payment_status, :paid_at,
                      :invoice_sent_at, :invoice_id, :repair_completed_at, :received_at, :assessed_at,
                      :shipping_cost, :is_returnable, :disposal_reason,
                      :return_address_line1, :return_address_line2, :return_city, :return_state, :return_zip])
      |> cast_assoc(:order_line_items, 
           sort_param: :order_line_items_sort,
           drop_param: :order_line_items_drop)
      |> validate_required([:service_level, :status, :user_id])
      |> validate_inclusion(:status, @statuses)
      |> validate_inclusion(:service_level, @service_levels)
      |> validate_inclusion(:payment_status, @payment_statuses)
      |> validate_order_line_items()
      |> calculate_order_total()
    
    # Only validate total_price and address on insert/update (not during form validation)
    case changeset.action do
      action when action in [:insert, :update] ->
        changeset
        |> validate_required([:total_price, :return_address_line1, :return_city, :return_state, :return_zip])
        |> validate_number(:total_price, greater_than: 0)
      _ ->
        changeset
    end
  end

  defp validate_order_line_items(changeset) do
    line_items = get_field(changeset, :order_line_items, [])
    
    if Enum.empty?(line_items) do
      add_error(changeset, :order_line_items, "must have at least one line item")
    else
      changeset
    end
  end

  defp calculate_order_total(changeset) do
    line_items = get_field(changeset, :order_line_items, [])
    volume_discount = get_field(changeset, :volume_discount, Decimal.new("0"))
    service_level = get_field(changeset, :service_level, "standard")
    
    # Calculate service multiplier
    service_multiplier = case service_level do
      "rush" -> Decimal.new("1.25")
      "priority" -> Decimal.new("1.5")
      "express" -> Decimal.new("1.75")
      _ -> Decimal.new("1.0")
    end
    
    line_items_total = Enum.reduce(line_items, Decimal.new("0"), fn line_item, acc ->
      line_total = case line_item do
        %OrderLineItem{line_total: total} when not is_nil(total) -> total
        %{line_total: total} when not is_nil(total) -> total
        _ -> Decimal.new("0")
      end
      Decimal.add(acc, line_total)
    end)
    
    # Apply service multiplier to total
    subtotal = Decimal.mult(line_items_total, service_multiplier)
    total_price = Decimal.sub(subtotal, volume_discount)
    
    put_change(changeset, :total_price, total_price)
  end

  def status_badge(status) do
    case status do
      "pending" -> {"Awaiting Shipment", "badge-warning"}
      "received" -> {"Received", "badge-info"}
      "assessed" -> {"Assessment Complete", "badge-info"}
      "repairing" -> {"Repairing", "badge-primary"}
      "invoice_sent" -> {"Invoice Sent", "badge-warning"}
      "paid" -> {"Paid", "badge-success"}
      "shipping_back" -> {"Shipping Back", "badge-primary"}
      "completed" -> {"Completed", "badge-success"}
      "cancelled" -> {"Cancelled", "badge-error"}
      _ -> {String.capitalize(status), "badge"}
    end
  end
end