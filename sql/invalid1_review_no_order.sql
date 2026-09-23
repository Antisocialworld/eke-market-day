-- ============================================================================
-- INVALID INSERT 1 — A Review with no Order.
-- Expected: FOREIGN KEY violation on Review.orderId -> Order.id.
-- ============================================================================
\set ON_ERROR_STOP off
INSERT INTO "Review"
  ("id", "orderId", "sellerId", "rating", "comment",
   "sellerResponse", "createdAt", "updatedAt")
VALUES (
  'proof_invalid_review_1',
  'nonexistent-order-id',
  (SELECT "id" FROM "User" WHERE "email" = 'obi@example.com'),
  5,
  'this review has no order',
  null,
  now(),
  now()
);