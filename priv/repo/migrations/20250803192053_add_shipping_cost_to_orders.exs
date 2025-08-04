defmodule BlindShop.Repo.Migrations.AddShippingCostToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :shipping_cost, :decimal, precision: 10, scale: 2, default: 0
      add :is_returnable, :boolean, default: true
      add :disposal_reason, :text
    end

    create index(:orders, [:is_returnable])
  end
end
