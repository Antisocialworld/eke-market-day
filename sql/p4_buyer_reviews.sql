-- ============================================================================
-- PROOF QUERY 4 — Action 4: A buyer leaves a review after a completed order.
-- The action's canonical pre-write query is
--   "which of my orders are completed and still unreviewed?"
--   WHERE "buyerId" = ? AND "status" = 'completed'
-- served by the composite Order(buyerId, status) index. Then a real review
-- insert: one review per order, UNIQUE(orderId) DB-enforced, about the SELLER.
-- ============================================================================

-- 1) New completed order for ada (the yam order is already reviewed, so we
--    create a second completed order to have one that is still unreviewed).
INSERT INTO "Order"
  ("id", "orderCode", "idempotencyKey", "buyerId", "listingId",
   "titleAtOrder", "priceMinorAtOrder", "currencyAtOrder",
   "shippingAddressAtOrder", "status", "createdAt", "updatedAt")
SELECT
  'proof_order_peppers_1',
  'EKE-PROOF-PEPPERS-1',
  'proof-idempotency-peppers-1',
  bu."id",
  l."id",
  l."title",
  l."priceMinor",
  l."currency",
  '12 Market Road, Enugu',
  'completed',
  now(),
  now()
FROM "User" bu, "Listing" l
WHERE bu."email" = 'ada@example.com'
  AND l."title" = 'Scotch bonnet peppers, bunch';

-- 2) The canonical "completed and still unreviewed" check for buyer ada.
SELECT o."orderCode", o."status",
       (SELECT count(*) FROM "Review" r WHERE r."orderId" = o."id") AS review_count
FROM "Order" o
WHERE o."buyerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'ada@example.com')
  AND o."status" = 'completed';

-- 3) Real review insert. sellerId is the order's seller, pinned from the
--    listing (D2); rating must satisfy CHECK (1..5).
INSERT INTO "Review"
  ("id", "orderId", "sellerId", "rating", "comment", "sellerResponse",
   "createdAt", "updatedAt")
SELECT
  'proof_review_peppers_1',
  'proof_order_peppers_1',
  l."sellerId",
  4,
  'Peppers were hot and fresh.',
  null,
  now(),
  now()
FROM "Order" o
JOIN "Listing" l ON o."listingId" = l."id"
WHERE o."id" = 'proof_order_peppers_1'
RETURNING "id", "orderId", "sellerId", "rating", "comment";