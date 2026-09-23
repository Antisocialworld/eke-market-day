-- ============================================================================
-- PROOF QUERY 1 — Action 1: A seller creates a listing.
-- The action's canonical query is the seller's own list view:
--   WHERE "sellerId" = ? ORDER BY "createdAt" DESC, served by Listing(sellerId).
-- Real insert (as the POST /listings writer would perform it), then the list.
-- ============================================================================

-- The seller (obi) creates a new listing.
INSERT INTO "Listing"
  ("id", "sellerId", "categoryId", "title", "description",
   "priceMinor", "currency", "status", "imageUrls", "createdAt", "updatedAt")
SELECT
  'proof_listing_obi_1',
  u."id",
  c."id",
  'Fresh groundnut oil, 1 litre',
  'Cold-pressed, no additives.',
  12000,
  'NGN',
  'active',
  '{}',
  now(),
  now()
FROM "User" u, "Category" c
WHERE u."email" = 'obi@example.com'
  AND c."name" = 'Pepper';

-- The seller's own list view (the query this action actually drives).
SELECT "id", "title", "priceMinor", "status", "createdAt"
FROM "Listing"
WHERE "sellerId" =
  (SELECT "id" FROM "User" WHERE "email" = 'obi@example.com')
ORDER BY "createdAt" DESC;