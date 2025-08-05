defmodule BlindShop.Repo.Migrations.RemoveShippingLabelUrlFromOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      remove :shipping_label_url, :string
    end
  end
end