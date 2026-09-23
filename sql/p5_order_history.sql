-- ============================================================================
-- PROOF QUERY 5 — Action 5: A buyer or seller views their own order history.
-- Buyer half:  WHERE "buyerId" = ? ORDER BY "createdAt" DESC
--   served by the Order(buyerId, status) composite (buyerId prefix).
-- Seller half: the same join shape as action 3 (Order(listingId) then
--   Listing(sellerId)). EXPLAIN output for both halves is in the 
--   explain files; this is the real output they would return.
-- ============================================================================

-- Buyer's own order history (ada's purchases, newest first).
SELECT "orderCode", "titleAtOrder", "priceMinorAtOrder", "currencyAtOrder",
       "status", "createdAt"
FROM "Order"
WHERE "buyerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'ada@example.com')
ORDER BY "createdAt" DESC;

-- Seller's own order history (obi's listings' orders, his fulfillment
-- pipeline across every status).
SELECT o."orderCode", o."titleAtOrder", o."priceMinorAtOrder",
       o."currencyAtOrder", o."status", o."createdAt"
FROM "Order" o
JOIN "Listing" l ON o."listingId" = l."id"
WHERE l."sellerId" =
        (SELECT "id" FROM "User" WHERE "email" = 'obi@example.com')
ORDER BY o."createdAt" DESC;