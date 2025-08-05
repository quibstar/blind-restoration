defmodule BlindShop.Repo.Migrations.AddCarrierToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :carrier, :string
    end
  end
end