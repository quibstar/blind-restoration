# BlindShop Project Roadmap

## 🎯 Project Vision
A mail-in blind repair service where customers get instant quotes based on blind dimensions, send their blinds for repair, and pay after the work is completed with option for shipping back or responsible disposal.

## 🚀 **CURRENT STATUS: MVP COMPLETE & DEPLOYED**
**All core functionality is built and ready for production!** The application is deployed to Fly.io with:
- ✅ Complete user & admin systems with authentication
- ✅ Multi-item order management with line items
- ✅ Post-repair payment workflow with Stripe integration  
- ✅ Professional HTML email templates with carrier tracking
- ✅ Admin dashboard for order management and invoicing
- ✅ Customer dashboard with real-time order tracking
- ✅ Flexible shipping/disposal system
- ✅ All Phase 1 & 2 features completed

**Next Step: Business operations setup and customer acquisition**

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

## 📊 Phase 2: Operations (Week 3-4) ✅ COMPLETED
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
  - **NEW**: Carrier tracking system with UPS, FedEx, USPS, DHL support
  - **NEW**: Direct tracking links in emails and dashboard
  - **NEW**: Removed shipping label complexity - simplified to customer ships their way

- [x] **Email Notifications** ✨ NOW COMPLETE!
  - Order confirmation (immediate after order creation)
  - Invoice ready notifications with payment links
  - Payment confirmation emails
  - Shipping and completion notifications
  - Email templates with proper Swoosh integration
  - Disposal notifications for non-returnable items
  - **NEW**: HTML email templates for all user authentication (login, confirmation, email updates)
  - **NEW**: Carrier-specific tracking with direct links to UPS, FedEx, USPS, DHL
  - **NEW**: Professional email branding with BlindRestoration styling

## 🏗️ Current Architecture Status

### ✅ Completed System Architecture
- **Separated Admin/User Contexts**: Complete separation between `BlindShop.Orders` (user-scoped) and `BlindShop.Admin.Orders` (full access)
- **Post-Repair Payment Workflow**: Changed from upfront payment to repair-first, invoice-after model
- **Database Polling**: Simple 30-second polling instead of complex real-time PubSub for better reliability
- **Flexible Disposal System**: Orders can be marked as non-returnable with disposal reasons tracked
- **Comprehensive Testing**: ExVCR cassettes for all Stripe integration scenarios
- **Route Handling**: Proper routing precedence for invoice payment callbacks
- **NEW**: Multi-item Order System with line items support
- **NEW**: Order Notes System for internal tracking and communication
- **NEW**: Carrier Tracking System with direct links to shipping providers
- **NEW**: HTML Email Templates with professional branding
- **NEW**: Account Deletion with feedback system for user privacy
- **NEW**: Migration cleanup and database optimization

### 🔧 Technical Decisions Made
1. **No Real-time Updates**: Opted for simple database polling over PubSub complexity
2. **Separate Admin Context**: Complete isolation of admin operations from user-scoped queries
3. **Post-repair Payment**: Better cash flow model - customers pay after seeing results
4. **Flexible Shipping**: Either ship back (with cost) or dispose responsibly
5. **String Metadata**: Stripe API requires string keys, not atom keys for metadata
6. **NO Shipping Labels**: Decided against pre-paid label complexity - customers ship their way
7. **Carrier Tracking**: Added carrier field for better customer tracking experience
8. **HTML Emails**: Full HTML email system with professional templates and branding

### 📋 Order Status Flow
```
Order Created → Received → Assessed → Repairing → Invoice Sent → Paid → Shipping Back → Completed
                                                      ↓
                                              (Alternative: Disposed)
```

## 📊 Phase 3: Business Operations (Month 2)
### Enhanced Features
- [ ] **Deployment & Production**
  - [x] Fly.io deployment configuration
  - [x] Database migrations for production
  - [x] Email configuration for production
  - [ ] Domain setup and SSL
  - [ ] Monitoring and error tracking
  - [ ] Backup strategies

- [ ] **Business Operations**
  - [ ] Actual shipping address and operations setup
  - [ ] Inventory management for cord colors/types
  - [ ] Quality control processes
  - [ ] Customer service workflows

- [ ] **Enhanced Customer Experience**
  - [ ] Photo upload for damage assessment
  - [ ] Before/after gallery
  - [ ] Custom quote requests for complex repairs
  - [ ] Cord color matching system
  - [ ] Rush service optimization

## 📊 Phase 4: Growth & Marketing (Month 3+)
### Content & SEO
- [ ] **Content Marketing**
  - Blog with repair tips and guides
  - Video tutorials for DIY assessment
  - SEO optimization for local markets
  - Social media presence

- [ ] **Service Expansion**
  - Motorization consultations
  - Child-safety conversions
  - Custom blind manufacturing
  - Commercial/bulk pricing

### Business Growth
- [ ] **Partner Program**
  - Property management companies
  - Interior designers
  - Real estate agents
  - Home improvement stores

- [ ] **Technology Expansion**
  - Mobile app for photo uploads
  - AR measurement tools
  - Live chat support
  - Review/rating system

## 💰 Revenue Projections
| Metric | Month 1 | Month 3 | Month 6 |
|--------|---------|---------|---------|
| Orders/week | 15 | 50 | 150 |
| Avg. ticket | $60 | $65 | $70 |
| Monthly revenue | $3,600 | $13,000 | $42,000 |

## 🎯 Success Metrics
- Customer satisfaction: >95%
- Turnaround time: <10 days (currently promoting "10-Day Turnaround")
- Return customer rate: >30%
- Google reviews: >4.5 stars
- **NEW**: Email delivery rate: >98%
- **NEW**: Tracking click-through rate: >80%
- **NEW**: Payment completion rate: >95%

## 🚀 Quick Wins
1. ✅ Launch with 5 blind types (mini, vertical, honeycomb, wood, roman)
2. [ ] Focus on local SEO and Google My Business
3. [ ] Partner with 1 property management company
4. [ ] Create viral TikTok/YouTube content showing repairs
5. [ ] Offer "first blind free" or discount promotion
6. [ ] Set up actual business operations and shipping facility
7. [ ] Implement customer feedback and review system
8. [ ] Create referral program with existing customers