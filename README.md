## Stripe

stripe login
stripe listen --forward-to localhost:4000/webhooks/stripe
stripe trigger payment_intent.succeeded
