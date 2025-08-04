defmodule BlindShop.Repo.Migrations.RemoveSingleItemFieldsFromOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      # Remove single-item fields that are now in order_line_items
      remove :blind_type, :string
      remove :width, :integer
      remove :height, :integer
      remove :quantity, :integer
      remove :base_price, :decimal
      remove :size_multiplier, :decimal
      remove :surcharge, :decimal
    end
  end
end
