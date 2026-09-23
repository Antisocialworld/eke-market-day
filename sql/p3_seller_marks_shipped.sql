-- ============================================================================
-- PROOF QUERY 3 — Action 3: A seller marks an order shipped.
-- The action's canonical query is the seller's fulfillment inbox:
--   JOIN "Listing" ON "Order"."listingId" = "Listing"."id"
--   WHERE "Listing"."sellerId" = ? AND "Order"."status" = ?
-- served by Listing(sellerId) then Order(listingId).
-- Real transition: the seller ships the currently-paid phone order.
-- ============================================================================

-- 1) The seller's fulfillment inbox (paid orders against their listings
--    to ship) — the query the action drives before the write.
SELECT o."id" AS order_id, o."orderCode", l."title", l."sellerId",
       o."status"
FROM "Order" o
JOIN "Listing" l ON o."listingId" = l."id"
WHERE l."sellerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'nkechi@example.com')
  AND o."status" = 'paid';

-- 2) The real state-machine transition: pending/paid -> shipped. The seller
--    ships the paid phone order their inbox returned above.
UPDATE "Order" o
SET "status" = 'shipped', "updatedAt" = now()
FROM "Listing" l
WHERE o."listingId" = l."id"
  AND l."sellerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'nkechi@example.com')
  AND o."status" = 'paid'
  AND l."title" = 'Refurbished Android phone'
RETURNING o."orderCode", o."status", o."updatedAt";