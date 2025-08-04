# BlindShop Project Roadmap

## 🎯 Project Vision
A mail-in blind repair service where customers get instant quotes based on blind dimensions, send their blinds for repair, and pay after the work is completed with option for shipping back or responsible disposal.

## 📊 Phase 1: MVP Launch (Week 1-2)
### Core Features
- [x] **Landing Page** with conversion-focused design
  - Hero section with clear value proposition
  - Instant quote calculator (width × height)
  - Trust indicators & social proof
  - How it works section
  - Dark/light mode toggle

- [x] **Quote System**
  - Dynamic pricing based on blind dimensions
  - Support for different blind types (mini, honeycomb, roman, vertical)
  - Rush service option (+50% fee)
  - Bulk discount calculator

- [x] **User Dashboard** (via phx.gen.auth) ✨ NOW COMPLETE!
  - Order tracking with 30-second database polling (no real-time WebSocket complexity)
  - Order history with timeline showing: Order Placed → Received → Assessed → Repaired → Paid → Shipped Back → Completed
  - Post-repair payment workflow with invoice notifications
  - Order status updates with visual indicators
  - Statistics overview (total orders, active, completed, total spent)
  - Quick actions for new orders and support

- [x] **Admin Panel** ✨ NOW COMPLETE!
  - Separated admin/user contexts for security
  - Order management with status progression buttons
  - Timeline shows repair workflow progress
  - Invoice generation modal with shipping cost and disposal options
  - Cancel order protection (disabled for completed orders)
  - Customer information and order details

## 📊 Phase 2: Operations (Week 3-4)
### Backend Systems
- [x] **Payment Integration** ✨ NOW COMPLETE!
  - Post-repair Stripe Checkout with invoice workflow
  - Webhook handling for payment confirmation
  - ExVCR test suite for reliable Stripe integration testing
  - String-key metadata format for Stripe API compatibility
  - Invoice-paid success page with shipping/disposal messaging
  - Email notifications with payment links

- [x] **Shipping Management** ✨ NOW COMPLETE!
  - Flexible shipping cost handling (added to invoice)
  - Option to dispose of badly damaged blinds instead of return shipping
  - Admin can set shipping costs or mark items as non-returnable
  - Shipping cost fields: shipping_cost, is_returnable, disposal_reason
  - Return shipping automation

- [x] **Email Notifications** ✨ NOW COMPLETE!
  - Order confirmation (immediate after order creation)
  - Invoice ready notifications with payment links
  - Payment confirmation emails
  - Shipping and completion notifications
  - Email templates with proper Swoosh integration
  - Disposal notifications for non-returnable items

## 🏗️ Current Architecture Status

### ✅ Completed System Architecture
- **Separated Admin/User Contexts**: Complete separation between `BlindShop.Orders` (user-scoped) and `BlindShop.Admin.Orders` (full access)
- **Post-Repair Payment Workflow**: Changed from upfront payment to repair-first, invoice-after model
- **Database Polling**: Simple 30-second polling instead of complex real-time PubSub for better reliability
- **Flexible Disposal System**: Orders can be marked as non-returnable with disposal reasons tracked
- **Comprehensive Testing**: ExVCR cassettes for all Stripe integration scenarios
- **Route Handling**: Proper routing precedence for invoice payment callbacks

### 🔧 Technical Decisions Made
1. **No Real-time Updates**: Opted for simple database polling over PubSub complexity
2. **Separate Admin Context**: Complete isolation of admin operations from user-scoped queries
3. **Post-repair Payment**: Better cash flow model - customers pay after seeing results
4. **Flexible Shipping**: Either ship back (with cost) or dispose responsibly
5. **String Metadata**: Stripe API requires string keys, not atom keys for metadata

### 📋 Order Status Flow
```
Order Created → Received → Assessed → Repairing → Invoice Sent → Paid → Shipping Back → Completed
                                                      ↓
                                              (Alternative: Disposed)
```

## 📊 Phase 3: Growth Features (Month 2)
### Enhanced Features
- [ ] **Photo Upload**
  - Before/after gallery
  - Damage assessment tool
  - Custom quote requests

- [ ] **Service Expansion**
  - Cord color upgrades
  - Child-safety conversions
  - Motorization consultations

- [ ] **Content Marketing**
  - Blog with repair tips
  - Video tutorials
  - SEO optimization

## 📊 Phase 4: Scale (Month 3+)
### Business Growth
- [ ] **Partner Program**
  - Property management companies
  - Interior designers
  - Real estate agents

- [ ] **Mobile App**
  - iOS/Android for easy photo uploads
  - Push notifications
  - AR measurement tool

- [ ] **Franchise Model**
  - Regional repair partners
  - Training program
  - Quality standards

## 💰 Revenue Projections
| Metric | Month 1 | Month 3 | Month 6 |
|--------|---------|---------|---------|
| Orders/week | 15 | 50 | 150 |
| Avg. ticket | $60 | $65 | $70 |
| Monthly revenue | $3,600 | $13,000 | $42,000 |

## 🎯 Success Metrics
- Customer satisfaction: >95%
- Turnaround time: <5 days
- Return customer rate: >30%
- Google reviews: >4.5 stars

## 🚀 Quick Wins
1. Launch with 3 blind types (most common)
2. Focus on local SEO first
3. Partner with 1 property management company
4. Create viral TikTok/YouTube content
5. Offer "first blind free" promotion