defmodule BlindShop.Orders.InvoiceLineItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias BlindShop.Orders.Order

  schema "invoice_line_items" do
    field :description, :string
    field :quantity, :integer, default: 1
    field :unit_price, :decimal
    field :total, :decimal
    field :line_order, :integer, default: 0

    belongs_to :order, Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:description, :quantity, :unit_price, :total, :line_order, :order_id])
    |> validate_required([:description, :quantity, :unit_price, :order_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
    |> calculate_total()
    |> foreign_key_constraint(:order_id)
  end

  defp calculate_total(changeset) do
    case {get_field(changeset, :quantity), get_field(changeset, :unit_price)} do
      {quantity, unit_price} when is_integer(quantity) and not is_nil(unit_price) ->
        total = Decimal.mult(Decimal.new(quantity), unit_price)
        put_change(changeset, :total, total)
      _ ->
        changeset
    end
  end
end