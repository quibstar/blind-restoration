defmodule BlindShop.Repo.Migrations.AddPaymentFieldsToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :checkout_session_id, :string
      add :payment_intent_id, :string
      add :payment_status, :string, default: "pending"
      add :paid_at, :utc_datetime
    end

    create index(:orders, [:checkout_session_id])
    create index(:orders, [:payment_intent_id])
    create index(:orders, [:payment_status])
  end
end
