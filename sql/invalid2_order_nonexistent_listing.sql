-- ============================================================================
-- INVALID INSERT 2 — An Order referencing a nonexistent Listing.
-- Expected: FOREIGN KEY violation on Order.listingId -> Listing.id.
-- ============================================================================
\set ON_ERROR_STOP off
INSERT INTO "Order"
  ("id", "orderCode", "idempotencyKey", "buyerId", "listingId",
   "titleAtOrder", "priceMinorAtOrder", "currencyAtOrder",
   "shippingAddressAtOrder", "status", "createdAt", "updatedAt")
SELECT
  'proof_invalid_order_2',
  'EKE-PROOF-INVALID-2',
  'proof-idempotency-invalid-2',
  "id",
  'nonexistent-listing-id',
  'ghost listing',
  1000,
  'NGN',
  '12 Market Road, Enugu',
  'pending',
  now(),
  now()
FROM "User" WHERE "email" = 'ada@example.com';