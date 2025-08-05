defmodule BlindShop.Orders.OrderNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_notes" do
    field :content, :string
    field :note_type, :string, default: "general"

    belongs_to :order, BlindShop.Orders.Order
    belongs_to :admin, BlindShop.Admins.Admin

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_note, attrs) do
    order_note
    |> cast(attrs, [:content, :note_type, :order_id, :admin_id])
    |> validate_required([:content, :order_id])
    |> validate_length(:content, min: 1, max: 2000)
    |> validate_inclusion(:note_type, ["general", "repair", "shipping", "payment", "customer_service"])
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:admin_id)
  end
end