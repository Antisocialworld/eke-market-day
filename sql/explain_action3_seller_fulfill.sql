-- ============================================================================
-- EXPLAIN ANALYZE — Action 3: seller's fulfillment inbox (the JOIN shape).
-- Expected: Index Scan on Order(listingId), Index Scan on Listing(sellerId).
-- ============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT o."id", o."orderCode", l."sellerId", o."status"
FROM "Order" o
JOIN "Listing" l ON o."listingId" = l."id"
WHERE l."sellerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'nkechi@example.com')
  AND o."status" = 'shipped';