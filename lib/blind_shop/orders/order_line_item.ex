defmodule BlindShop.Orders.OrderLineItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlindShop.Orders.Order

  schema "order_line_items" do
    field :blind_type, :string
    field :width, :integer
    field :height, :integer
    field :quantity, :integer, default: 1
    field :cord_color, :string
    field :base_price, :decimal
    field :size_multiplier, :decimal
    field :surcharge, :decimal, default: Decimal.new("0")
    field :line_total, :decimal
    field :line_order, :integer, default: 0
    field :temp_id, :string

    belongs_to :order, Order

    timestamps(type: :utc_datetime)
  end

  @blind_types ~w(mini vertical honeycomb wood roman)
  @cord_colors ~w(white beige tan brown black gray)

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:blind_type, :width, :height, :quantity, :cord_color,
                    :base_price, :size_multiplier, :surcharge, :line_total, :line_order, 
                    :temp_id, :order_id])
    |> validate_required([:blind_type, :width, :height, :quantity])
    |> validate_inclusion(:blind_type, @blind_types)
    |> validate_inclusion(:cord_color, @cord_colors, allow_blank: true)
    |> validate_number(:width, greater_than: 0, less_than_or_equal_to: 144)
    |> validate_number(:height, greater_than: 0, less_than_or_equal_to: 144)
    |> validate_number(:quantity, greater_than: 0)
    |> calculate_pricing()
    |> foreign_key_constraint(:order_id)
  end

  defp calculate_pricing(changeset) do
    case {get_field(changeset, :blind_type), get_field(changeset, :width), 
          get_field(changeset, :height), get_field(changeset, :quantity)} do
      {blind_type, width, height, quantity} 
      when is_binary(blind_type) and is_integer(width) and is_integer(height) 
      and is_integer(quantity) ->

        # Base prices by blind type
        base_prices = %{
          "mini" => 55,
          "vertical" => 70,
          "honeycomb" => 85,
          "wood" => 95,
          "roman" => 110
        }

        base_price = Decimal.new(base_prices[blind_type] || 55)
        sqft = (width * height) / 144.0

        # Size multiplier
        size_multiplier = cond do
          sqft <= 15 -> Decimal.new("1.0")
          sqft <= 25 -> Decimal.new("1.2")
          sqft <= 35 -> Decimal.new("1.4")
          sqft <= 50 -> Decimal.new("1.7")
          sqft <= 70 -> Decimal.new("2.0")
          true -> Decimal.new("2.5")
        end

        # Surcharges
        surcharge = cond do
          width > 72 && height > 84 -> Decimal.new("40")
          width > 72 -> Decimal.new("25")
          height > 84 -> Decimal.new("20")
          true -> Decimal.new("0")
        end

        # Calculate base line total (without service multiplier, applied at order level)
        subtotal = base_price
                   |> Decimal.mult(size_multiplier)
                   |> Decimal.mult(Decimal.new(quantity))
                   |> Decimal.add(surcharge)

        line_total = Decimal.round(subtotal, 2)

        changeset
        |> put_change(:base_price, base_price)
        |> put_change(:size_multiplier, size_multiplier)
        |> put_change(:surcharge, surcharge)
        |> put_change(:line_total, line_total)

      _ ->
        changeset
    end
  end

  @doc """
  Calculate line item total with service level applied from order.
  """
  def calculate_total_with_service(%__MODULE__{} = line_item, service_level) when is_binary(service_level) do
    service_multiplier = case service_level do
      "rush" -> Decimal.new("1.25")
      "priority" -> Decimal.new("1.5")
      "express" -> Decimal.new("1.75")
      _ -> Decimal.new("1.0")
    end

    line_item.line_total
    |> Decimal.mult(service_multiplier)
    |> Decimal.round(2)
  end
end