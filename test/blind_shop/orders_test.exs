defmodule BlindShop.OrdersTest do
  use BlindShop.DataCase

  alias BlindShop.Orders

  describe "orders" do
    alias BlindShop.Orders.Order

    import BlindShop.AccountsFixtures, only: [user_scope_fixture: 0]
    import BlindShop.OrdersFixtures

    @invalid_attrs %{status: nil, width: nil, blind_type: nil, height: nil, quantity: nil, service_level: nil, base_price: nil, total_price: nil, tracking_number: nil, notes: nil}

    test "list_orders/1 returns all scoped orders" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      order = order_fixture(scope)
      other_order = order_fixture(other_scope)
      assert Orders.list_orders(scope) == [order]
      assert Orders.list_orders(other_scope) == [other_order]
    end

    test "get_order!/2 returns the order with given id" do
      scope = user_scope_fixture()
      order = order_fixture(scope)
      other_scope = user_scope_fixture()
      assert Orders.get_order!(scope, order.id) == order
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(other_scope, order.id) end
    end

    test "create_order/2 with valid data creates a order" do
      valid_attrs = %{status: "some status", width: 42, blind_type: "some blind_type", height: 42, quantity: 42, service_level: "some service_level", base_price: "120.5", total_price: "120.5", tracking_number: "some tracking_number", notes: "some notes"}
      scope = user_scope_fixture()

      assert {:ok, %Order{} = order} = Orders.create_order(scope, valid_attrs)
      assert order.status == "some status"
      assert order.width == 42
      assert order.blind_type == "some blind_type"
      assert order.height == 42
      assert order.quantity == 42
      assert order.service_level == "some service_level"
      assert order.base_price == Decimal.new("120.5")
      assert order.total_price == Decimal.new("120.5")
      assert order.tracking_number == "some tracking_number"
      assert order.notes == "some notes"
      assert order.user_id == scope.user.id
    end

    test "create_order/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(scope, @invalid_attrs)
    end

    test "update_order/3 with valid data updates the order" do
      scope = user_scope_fixture()
      order = order_fixture(scope)
      update_attrs = %{status: "some updated status", width: 43, blind_type: "some updated blind_type", height: 43, quantity: 43, service_level: "some updated service_level", base_price: "456.7", total_price: "456.7", tracking_number: "some updated tracking_number", notes: "some updated notes"}

      assert {:ok, %Order{} = order} = Orders.update_order(scope, order, update_attrs)
      assert order.status == "some updated status"
      assert order.width == 43
      assert order.blind_type == "some updated blind_type"
      assert order.height == 43
      assert order.quantity == 43
      assert order.service_level == "some updated service_level"
      assert order.base_price == Decimal.new("456.7")
      assert order.total_price == Decimal.new("456.7")
      assert order.tracking_number == "some updated tracking_number"
      assert order.notes == "some updated notes"
    end

    test "update_order/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      order = order_fixture(scope)

      assert_raise MatchError, fn ->
        Orders.update_order(other_scope, order, %{})
      end
    end

    test "update_order/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      order = order_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(scope, order, @invalid_attrs)
      assert order == Orders.get_order!(scope, order.id)
    end

    test "delete_order/2 deletes the order" do
      scope = user_scope_fixture()
      order = order_fixture(scope)
      assert {:ok, %Order{}} = Orders.delete_order(scope, order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(scope, order.id) end
    end

    test "delete_order/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      order = order_fixture(scope)
      assert_raise MatchError, fn -> Orders.delete_order(other_scope, order) end
    end

    test "change_order/2 returns a order changeset" do
      scope = user_scope_fixture()
      order = order_fixture(scope)
      assert %Ecto.Changeset{} = Orders.change_order(scope, order)
    end
  end
end
