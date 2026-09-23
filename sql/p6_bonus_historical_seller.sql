-- ============================================================================
-- PROOF QUERY 6 (BONUS, CONFIRMED) — the historical-seller lookup.
--
-- Scenario (seeded, real): a listing was owned by seller A; an order was
-- placed while A still owned it (order.createdAt is inside A's ownership);
-- THEN the listing was transferred A -> B (write-first, one transaction)
-- and Listing.sellerId now reads B. The lookup below must return A — the
-- ORIGINAL seller — not B.
--
-- CORRECTED 3-BRANCH PATTERN (documented deviation from Part 3's original
-- 2-branch SQL; see the reasoning and trace in DOCUMENTATION.md Step 5 and
-- EKE-MARKET-DAY-COMBINED.md Part 3 SKILL):
--   branch 1: newest transfer whose transferredAt <= order.createdAt  -> its newSeller
--   branch 2: if no such transfer, the OWNER WHO PRECEDED THE FIRST TRANSFER
--             (the previousSeller of the earliest transfer) -> the builder/original
--             owner for an order placed before any ownership change
--   branch 3: fallback, no transfer ever happened -> Listing.sellerId
-- Original 2-branch SQL was missing branch 2: for an order placed before the
-- ONLY transfer, it fell back to today's owner (B) instead of the true owner
-- at order time (A).
-- ============================================================================

-- Capture the real seeded inputs: the basket listing id and the order's own
-- createdAt (the order placed while A still owned the listing).
SELECT b."id" AS bid, o."createdAt" AS ocreated, o."orderCode" AS ocode
FROM "Listing" b
JOIN "Order" o ON o."listingId" = b."id"
WHERE b."title" = 'Hand-woven raffia basket'
  AND o."status" = 'paid'
\gset

-- Show today's ownership (should read B = obi) and the transfer history.
SELECT 'current seller of the listing today' AS step, "sellerId" AS value
FROM "Listing" WHERE "id" = :'bid';
SELECT 'newest transfer (A=nkechi -> B=obi)' AS step,
       "previousSellerId", "newSellerId", "transferredAt"
FROM "ListingOwnershipTransfer" WHERE "listingId" = :'bid'
ORDER BY "transferredAt";

-- THE REAL LOOKUP: $1 = the order's listingId, $2 = the order's own createdAt.
-- Corrected 3-branch version.
SELECT COALESCE(
  (SELECT "newSellerId" FROM "ListingOwnershipTransfer"
   WHERE "listingId" = :'bid' AND "transferredAt" <= :'ocreated'
   ORDER BY "transferredAt" DESC LIMIT 1),
  (SELECT "previousSellerId" FROM "ListingOwnershipTransfer"
   WHERE "listingId" = :'bid'
   ORDER BY "transferredAt" ASC LIMIT 1),
  (SELECT "sellerId" FROM "Listing" WHERE "id" = :'bid')
) AS historical_seller_id
\gset

SELECT :'historical_seller_id' AS historical_seller_id;
SELECT :'ocreated' AS order_created_at;
SELECT :'ocode' AS order_code;

-- The proof: historical owner must equal the ORIGINAL seller (nkechi, the
-- true seller at order time), NOT today's owner (obi). Assert it in SQL.
SELECT CASE
  WHEN :'historical_seller_id' =
         (SELECT "id" FROM "User" WHERE "email" = 'nkechi@example.com')
  THEN 'PASS: historical seller is the ORIGINAL owner (A = nkechi)'
  ELSE 'FAIL: historical seller resolved to the wrong user'
END AS bonus_query_result;

-- Real EXPLAIN of the 3-branch lookup: the (listingId, transferredAt)
-- composite index must be used for the window subquery.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COALESCE(
  (SELECT "newSellerId" FROM "ListingOwnershipTransfer"
   WHERE "listingId" = :'bid' AND "transferredAt" <= :'ocreated'
   ORDER BY "transferredAt" DESC LIMIT 1),
  (SELECT "previousSellerId" FROM "ListingOwnershipTransfer"
   WHERE "listingId" = :'bid'
   ORDER BY "transferredAt" ASC LIMIT 1),
  (SELECT "sellerId" FROM "Listing" WHERE "id" = :'bid')
) AS historical_seller_id;