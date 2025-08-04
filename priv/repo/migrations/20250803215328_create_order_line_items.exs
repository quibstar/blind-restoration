defmodule BlindShop.Repo.Migrations.CreateOrderLineItems do
  use Ecto.Migration

  def change do
    create table(:order_line_items) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :blind_type, :string, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :quantity, :integer, default: 1
      add :service_level, :string, default: "standard"
      add :cord_color, :string
      add :base_price, :decimal, precision: 10, scale: 2, null: false
      add :size_multiplier, :decimal, precision: 4, scale: 2, null: false
      add :surcharge, :decimal, precision: 10, scale: 2, default: 0
      add :line_total, :decimal, precision: 10, scale: 2, null: false
      add :line_order, :integer, default: 0
      add :temp_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:order_line_items, [:order_id])
    create index(:order_line_items, [:order_id, :line_order])
    create index(:order_line_items, [:cord_color])
  end
end
