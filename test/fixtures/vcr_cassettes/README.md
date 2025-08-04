# ExVCR Cassettes for Invoice Service Tests

This directory contains HTTP interaction recordings for testing the Stripe integration in the Invoice Service.

## 📁 Cassette Files

### Invoice Generation Tests
- **`invoice_with_shipping_success.json`** - Successful invoice creation with shipping costs for returnable blinds
- **`invoice_disposal_success.json`** - Successful invoice creation for non-returnable (disposed) blinds  
- **`invoice_line_items_test.json`** - Test for correct line item structure (repair + shipping)
- **`invoice_stripe_error.json`** - Stripe API error response (expired API key)

### Payment Processing Tests
- **`payment_success.json`** - Successful payment completion via webhook
- **`payment_retrieval_error.json`** - Error retrieving invalid session ID

## 🔄 Recording New Cassettes

To record new cassettes with real Stripe interactions:

1. **Set environment variables:**
   ```bash
   export STRIPE_TEST_SECRET_KEY=sk_test_your_real_test_key
   export STRIPE_TEST_PUBLISHABLE_KEY=pk_test_your_real_publishable_key
   ```

2. **Delete existing cassette:**
   ```bash
   rm test/fixtures/vcr_cassettes/your_test_cassette.json
   ```

3. **Run the specific test:**
   ```bash
   mix test test/blind_shop/payments/invoice_service_test.exs:line_number
   ```

4. **Review and sanitize the recorded cassette** - Make sure no real API keys or sensitive data are saved.

## 🔒 Security Notes

- All API keys in cassettes are replaced with placeholders like `STRIPE_SECRET_KEY`
- Email addresses use test domains (`test@example.com`)
- All session IDs, payment intent IDs are test values
- Never commit real production keys or customer data

## 🧪 Test Scenarios Covered

### ✅ Success Paths
- Invoice generation with shipping costs
- Invoice generation for disposal cases
- Payment completion handling
- Database updates verification

### ❌ Error Paths  
- Invalid API keys
- Missing session IDs
- Stripe service errors
- Network failures

## 🚀 Running Tests

```bash
# Run all invoice service tests
mix test test/blind_shop/payments/invoice_service_test.exs

# Run only VCR tests (skip mock tests)
mix test test/blind_shop/payments/invoice_service_test.exs --only vcr

# Run without VCR (uses mock sessions)
mix test test/blind_shop/payments/invoice_service_test.exs --exclude vcr
```

## 🔄 Updating Cassettes

When the Stripe API changes or you need to add new test scenarios:

1. Update the test code with new assertions
2. Delete the relevant cassette file  
3. Run the test to record new interactions
4. Verify the cassette contains expected data
5. Commit the updated cassette file