defmodule BlindShop.Repo.Migrations.AddOrdersTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:orders) do
      add :blind_type, :string, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :quantity, :integer, null: false, default: 1
      add :service_level, :string, null: false, default: "standard"
      add :base_price, :decimal, precision: 10, scale: 2, null: false
      add :size_multiplier, :decimal, precision: 5, scale: 2, null: false
      add :surcharge, :decimal, precision: 10, scale: 2, default: 0
      add :volume_discount, :decimal, precision: 10, scale: 2, default: 0
      add :total_price, :decimal, precision: 10, scale: 2, null: false
      add :status, :string, null: false, default: "pending"
      add :tracking_number, :string
      add :shipping_label_url, :string
      add :notes, :text
      add :shipped_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :last_reminder_sent_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists index(:orders, [:user_id])
    create_if_not_exists index(:orders, [:status])
    create_if_not_exists index(:orders, [:inserted_at])
  end
end