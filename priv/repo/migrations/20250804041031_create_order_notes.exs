defmodule BlindShop.Repo.Migrations.CreateOrderNotes do
  use Ecto.Migration

  def change do
    create table(:order_notes) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :admin_id, references(:admins, on_delete: :nilify_all)
      add :content, :text, null: false
      add :note_type, :string, default: "general"
      
      timestamps(type: :utc_datetime)
    end

    create index(:order_notes, [:order_id])
    create index(:order_notes, [:admin_id])
    create index(:order_notes, [:inserted_at])
  end
end
