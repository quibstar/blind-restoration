defmodule BlindShop.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BlindShop.Orders` context.
  """

  @doc """
  Generate a order.
  """
  def order_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        base_price: "120.5",
        blind_type: "some blind_type",
        height: 42,
        notes: "some notes",
        quantity: 42,
        service_level: "some service_level",
        status: "some status",
        total_price: "120.5",
        tracking_number: "some tracking_number",
        width: 42
      })

    {:ok, order} = BlindShop.Orders.create_order(scope, attrs)
    order
  end
end
