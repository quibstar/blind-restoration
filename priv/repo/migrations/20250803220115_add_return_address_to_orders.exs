defmodule BlindShop.Repo.Migrations.AddReturnAddressToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :return_address_line1, :string
      add :return_address_line2, :string
      add :return_city, :string
      add :return_state, :string
      add :return_zip, :string
    end
  end
end