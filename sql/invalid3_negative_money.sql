-- ============================================================================
-- INVALID INSERT 3 — A negative money value.
-- Expected: CHECK constraint order_price_non_negative violation
--   ("priceMinorAtOrder" >= 0), the REQUIRED Q2 guard, not an optional case.
-- ============================================================================
\set ON_ERROR_STOP off
INSERT INTO "Order"
  ("id", "orderCode", "idempotencyKey", "buyerId", "listingId",
   "titleAtOrder", "priceMinorAtOrder", "currencyAtOrder",
   "shippingAddressAtOrder", "status", "createdAt", "updatedAt")
SELECT
  'proof_invalid_order_3',
  'EKE-PROOF-INVALID-3',
  'proof-idempotency-invalid-3',
  "id",
  (SELECT "id" FROM "Listing" LIMIT 1),
  'negative price order',
  -500,
  'NGN',
  '12 Market Road, Enugu',
  'pending',
  now(),
  now()
FROM "User" WHERE "email" = 'ada@example.com';