defmodule BlindShopWeb.OrderLiveTest do
  use BlindShopWeb.ConnCase

  import Phoenix.LiveViewTest
  import BlindShop.OrdersFixtures

  @create_attrs %{status: "some status", width: 42, blind_type: "some blind_type", height: 42, quantity: 42, service_level: "some service_level", base_price: "120.5", total_price: "120.5", tracking_number: "some tracking_number", notes: "some notes"}
  @update_attrs %{status: "some updated status", width: 43, blind_type: "some updated blind_type", height: 43, quantity: 43, service_level: "some updated service_level", base_price: "456.7", total_price: "456.7", tracking_number: "some updated tracking_number", notes: "some updated notes"}
  @invalid_attrs %{status: nil, width: nil, blind_type: nil, height: nil, quantity: nil, service_level: nil, base_price: nil, total_price: nil, tracking_number: nil, notes: nil}

  setup :register_and_log_in_user

  defp create_order(%{scope: scope}) do
    order = order_fixture(scope)

    %{order: order}
  end

  describe "Index" do
    setup [:create_order]

    test "lists all orders", %{conn: conn, order: order} do
      {:ok, _index_live, html} = live(conn, ~p"/orders")

      assert html =~ "Listing Orders"
      assert html =~ order.blind_type
    end

    test "saves new order", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Order")
               |> render_click()
               |> follow_redirect(conn, ~p"/orders/new")

      assert render(form_live) =~ "New Order"

      assert form_live
             |> form("#order-form", order: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#order-form", order: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orders")

      html = render(index_live)
      assert html =~ "Order created successfully"
      assert html =~ "some blind_type"
    end

    test "updates order in listing", %{conn: conn, order: order} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#orders-#{order.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/orders/#{order}/edit")

      assert render(form_live) =~ "Edit Order"

      assert form_live
             |> form("#order-form", order: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#order-form", order: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orders")

      html = render(index_live)
      assert html =~ "Order updated successfully"
      assert html =~ "some updated blind_type"
    end

    test "deletes order in listing", %{conn: conn, order: order} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert index_live |> element("#orders-#{order.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#orders-#{order.id}")
    end
  end

  describe "Show" do
    setup [:create_order]

    test "displays order", %{conn: conn, order: order} do
      {:ok, _show_live, html} = live(conn, ~p"/orders/#{order}")

      assert html =~ "Show Order"
      assert html =~ order.blind_type
    end

    test "updates order and returns to show", %{conn: conn, order: order} do
      {:ok, show_live, _html} = live(conn, ~p"/orders/#{order}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/orders/#{order}/edit?return_to=show")

      assert render(form_live) =~ "Edit Order"

      assert form_live
             |> form("#order-form", order: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#order-form", order: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orders/#{order}")

      html = render(show_live)
      assert html =~ "Order updated successfully"
      assert html =~ "some updated blind_type"
    end
  end
end
