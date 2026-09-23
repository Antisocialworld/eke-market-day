-- ============================================================================
-- EXPLAIN ANALYZE — Action 5: buyer's own order history.
-- Canonical query from Part A: WHERE "buyerId" = ? ORDER BY "createdAt" DESC.
-- Expected: Index Scan using Order(buyerId, status) — the buyerId prefix.
-- ============================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT "id", "orderCode", "titleAtOrder", "priceMinorAtOrder",
       "currencyAtOrder", "status"
FROM "Order"
WHERE "buyerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'ada@example.com')
ORDER BY "createdAt" DESC;