defmodule BlindShop.Repo.Migrations.CreateInvoiceLineItems do
  use Ecto.Migration

  def change do
    create table(:invoice_line_items) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :description, :string, null: false
      add :quantity, :integer, null: false, default: 1
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :total, :decimal, precision: 10, scale: 2, null: false
      add :line_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:invoice_line_items, [:order_id])
    create index(:invoice_line_items, [:order_id, :line_order])
  end
end
