defmodule BlindShop.Payments.InvoiceServiceTest do
  use BlindShop.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias BlindShop.Payments.InvoiceService
  alias BlindShop.Admin.Orders, as: AdminOrders
  alias BlindShop.Orders
  alias BlindShop.Accounts

  describe "generate_invoice/1" do
    setup do
      # Create test user
      user = insert(:user, email: "test@example.com", first_name: "John", last_name: "Doe")
      
      # Create test order with shipping fields
      order = insert(:order, 
        user: user,
        blind_type: "vertical",
        width: 48,
        height: 72,
        quantity: 2,
        service_level: "standard",
        total_price: Decimal.new("85.50"),
        status: "repairing",
        shipping_cost: Decimal.new("15.00"),
        is_returnable: true
      )
      
      %{user: user, order: order}
    end

    @tag :vcr
    test "creates invoice with shipping cost for returnable blinds", %{order: order} do
      use_cassette "invoice_with_shipping_success" do
        assert {:ok, updated_order} = InvoiceService.generate_invoice(order)
        
        # Check order was updated
        assert updated_order.status == "invoice_sent"
        assert updated_order.payment_status == "invoice_sent"
        assert updated_order.invoice_id != nil
        assert updated_order.invoice_sent_at != nil
        assert updated_order.checkout_session_id != nil
        
        # Reload from database to verify persistence
        db_order = AdminOrders.get_order!(order.id)
        assert db_order.status == "invoice_sent"
        assert db_order.invoice_id == updated_order.invoice_id
      end
    end

    @tag :vcr
    test "creates invoice without shipping for non-returnable blinds", %{order: order} do
      # Update order to be non-returnable
      {:ok, non_returnable_order} = AdminOrders.update_order(order, %{
        is_returnable: false,
        disposal_reason: "Too damaged to return safely",
        shipping_cost: Decimal.new("0")
      })
      
      use_cassette "invoice_disposal_success" do
        assert {:ok, updated_order} = InvoiceService.generate_invoice(non_returnable_order)
        
        # Check order was updated
        assert updated_order.status == "invoice_sent"
        assert updated_order.is_returnable == false
        assert updated_order.disposal_reason == "Too damaged to return safely"
        
        # Verify no shipping costs in this scenario
        assert Decimal.compare(updated_order.shipping_cost, Decimal.new("0")) == :eq
      end
    end

    test "uses mock session when Stripe API key is not configured" do
      # Temporarily remove Stripe API key
      original_key = Application.get_env(:stripity_stripe, :api_key)
      Application.put_env(:stripity_stripe, :api_key, nil)
      
      try do
        order = insert(:order, 
          status: "repairing",
          shipping_cost: Decimal.new("12.50"),
          is_returnable: true
        )
        
        assert {:ok, updated_order} = InvoiceService.generate_invoice(order)
        
        # Check mock session was created
        assert updated_order.status == "invoice_sent"
        assert String.starts_with?(updated_order.invoice_id, "cs_test_mock_")
        assert String.contains?(updated_order.checkout_session_id, "mock")
      after
        # Restore original key
        Application.put_env(:stripity_stripe, :api_key, original_key)
      end
    end

    @tag :vcr
    test "handles Stripe API errors gracefully", %{order: order} do
      use_cassette "invoice_stripe_error" do
        # This cassette should contain a Stripe error response
        assert {:error, error_message} = InvoiceService.generate_invoice(order)
        assert is_binary(error_message)
        
        # Order should not be updated on error
        db_order = AdminOrders.get_order!(order.id)
        assert db_order.status == "repairing"  # Still original status
        assert db_order.invoice_id == nil
      end
    end

    test "calculates correct line items for shipping", %{order: order} do
      # Test the line items structure without hitting Stripe
      use_cassette "invoice_line_items_test" do
        assert {:ok, updated_order} = InvoiceService.generate_invoice(order)
        
        # The invoice should include both repair service and shipping
        # We can't directly inspect the Stripe call params, but we can verify
        # the order fields that would be used to build line items
        assert Decimal.compare(updated_order.total_price, Decimal.new("85.50")) == :eq
        assert Decimal.compare(updated_order.shipping_cost, Decimal.new("15.00")) == :eq
        assert updated_order.is_returnable == true
      end
    end
  end

  describe "handle_invoice_payment/1" do
    setup do
      user = insert(:user)
      order = insert(:order, 
        user: user,
        status: "invoice_sent",
        invoice_id: "cs_test_123",
        checkout_session_id: "cs_test_123"
      )
      
      %{user: user, order: order}
    end

    @tag :vcr
    test "marks order as paid when payment succeeds", %{order: order} do
      session_id = order.checkout_session_id
      
      use_cassette "payment_success" do
        assert {:ok, updated_order} = InvoiceService.handle_invoice_payment(session_id)
        
        assert updated_order.status == "paid"
        assert updated_order.payment_status == "paid"
        assert updated_order.paid_at != nil
        assert updated_order.payment_intent_id != nil
      end
    end

    @tag :vcr  
    test "handles payment retrieval errors", _context do
      invalid_session_id = "cs_test_invalid_12345"
      
      use_cassette "payment_retrieval_error" do
        assert {:error, error_message} = InvoiceService.handle_invoice_payment(invalid_session_id)
        assert is_binary(error_message)
      end
    end
  end

  # Helper to create test data - you may need to adjust based on your factory setup
  defp insert(schema, attrs \\ %{}) do
    case schema do
      :user ->
        default_attrs = %{
          email: "user#{:rand.uniform(10000)}@example.com",
          first_name: "Test",
          last_name: "User",
          confirmed_at: DateTime.utc_now()
        }
        attrs = Map.merge(default_attrs, attrs)
        {:ok, user} = Accounts.register_user(attrs)
        user

      :order ->
        user = attrs[:user] || insert(:user)
        default_attrs = %{
          user_id: user.id,
          blind_type: "horizontal",
          width: 36,
          height: 48,
          quantity: 1,
          service_level: "standard",
          base_price: Decimal.new("45.00"),
          size_multiplier: Decimal.new("1.2"),
          surcharge: Decimal.new("0"),
          volume_discount: Decimal.new("0"),
          total_price: Decimal.new("54.00"),
          status: "pending",
          shipping_cost: Decimal.new("0"),
          is_returnable: true
        }
        attrs = Map.merge(default_attrs, attrs) |> Map.delete(:user)
        {:ok, order} = Orders.create_order(%{user: user}, attrs)
        order
    end
  end
end