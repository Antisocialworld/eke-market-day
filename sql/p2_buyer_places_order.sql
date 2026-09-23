-- ============================================================================
-- PROOF QUERY 2 — Action 2: A buyer places an order.
-- The action's canonical query is the snapshot read at commit:
--   SELECT ... FROM "Listing" WHERE "id" = ?
-- (served by the Listing PRIMARY KEY), then a real order insert whose
-- snapshot columns (title/price/currency) are copied FROM the listing row,
-- never supplied by the client (D1).
-- ============================================================================

-- 1) Snapshot read: fetch the exact listing by id (PRIMARY KEY serve).
SELECT "id", "title", "priceMinor", "currency", "sellerId", "status"
FROM "Listing"
WHERE "id" =
  (SELECT "id" FROM "Listing" WHERE "title" = 'Refurbished Android phone')
  AND "status" = 'active';

-- 2) Real order insert: buyer ada buys that listing; snapshot columns come
--    from the listing itself inside the same statement.
INSERT INTO "Order"
  ("id", "orderCode", "idempotencyKey", "buyerId", "listingId",
   "titleAtOrder", "priceMinorAtOrder", "currencyAtOrder",
   "shippingAddressAtOrder", "status", "createdAt", "updatedAt")
SELECT
  'proof_order_phone_1',
  'EKE-PROOF-PHONE-1',
  'proof-idempotency-phone-1',
  bu."id",
  l."id",
  l."title",
  l."priceMinor",
  l."currency",
  '12 Market Road, Enugu',
  'pending',
  now(),
  now()
FROM "User" bu, "Listing" l
WHERE bu."email" = 'ada@example.com'
  AND l."title" = 'Refurbished Android phone';

-- The placed order, as the buyer is given back (the response row).
SELECT "id", "orderCode", "buyerId", "listingId",
       "titleAtOrder", "priceMinorAtOrder", "currencyAtOrder", "status"
FROM "Order"
WHERE "orderCode" = 'EKE-PROOF-PHONE-1';