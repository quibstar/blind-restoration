defmodule BlindShop.Repo.Migrations.AddInvoiceAndRepairFieldsToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :invoice_sent_at, :utc_datetime
      add :invoice_id, :string
      add :repair_completed_at, :utc_datetime
      add :received_at, :utc_datetime
      add :assessed_at, :utc_datetime
    end

    create index(:orders, [:invoice_id])
    create index(:orders, [:repair_completed_at])
    create index(:orders, [:received_at])
  end
end
