-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "isBuyer" BOOLEAN NOT NULL DEFAULT false,
    "isSeller" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Category" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "parentId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Listing" (
    "id" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "priceMinor" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'NGN',
    "status" TEXT NOT NULL DEFAULT 'active',
    "imageUrls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Listing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ListingOwnershipTransfer" (
    "id" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "previousSellerId" TEXT NOT NULL,
    "newSellerId" TEXT NOT NULL,
    "transferredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ListingOwnershipTransfer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Order" (
    "id" TEXT NOT NULL,
    "orderCode" TEXT NOT NULL,
    "idempotencyKey" TEXT,
    "buyerId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "titleAtOrder" TEXT NOT NULL,
    "priceMinorAtOrder" INTEGER NOT NULL,
    "currencyAtOrder" TEXT NOT NULL DEFAULT 'NGN',
    "shippingAddressAtOrder" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "sellerResponse" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Category_name_key" ON "Category"("name");

-- CreateIndex
CREATE INDEX "Category_parentId_idx" ON "Category"("parentId");

-- CreateIndex
CREATE INDEX "Listing_sellerId_idx" ON "Listing"("sellerId");

-- CreateIndex
CREATE INDEX "Listing_categoryId_idx" ON "Listing"("categoryId");

-- CreateIndex
CREATE INDEX "ListingOwnershipTransfer_listingId_transferredAt_idx" ON "ListingOwnershipTransfer"("listingId", "transferredAt");

-- CreateIndex
CREATE UNIQUE INDEX "Order_orderCode_key" ON "Order"("orderCode");

-- CreateIndex
CREATE UNIQUE INDEX "Order_idempotencyKey_key" ON "Order"("idempotencyKey");

-- CreateIndex
CREATE INDEX "Order_buyerId_status_idx" ON "Order"("buyerId", "status");

-- CreateIndex
CREATE INDEX "Order_listingId_idx" ON "Order"("listingId");

-- CreateIndex
CREATE UNIQUE INDEX "Review_orderId_key" ON "Review"("orderId");

-- CreateIndex
CREATE INDEX "Review_sellerId_idx" ON "Review"("sellerId");

-- AddForeignKey
ALTER TABLE "Category" ADD CONSTRAINT "Category_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Listing" ADD CONSTRAINT "Listing_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Listing" ADD CONSTRAINT "Listing_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ListingOwnershipTransfer" ADD CONSTRAINT "ListingOwnershipTransfer_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ListingOwnershipTransfer" ADD CONSTRAINT "ListingOwnershipTransfer_previousSellerId_fkey" FOREIGN KEY ("previousSellerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ListingOwnershipTransfer" ADD CONSTRAINT "ListingOwnershipTransfer_newSellerId_fkey" FOREIGN KEY ("newSellerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- =====================================================================
-- Deliberate raw-SQL CHECK constraints (Prisma schema cannot express
-- CHECK; these are REQUIRED per Part A Step 3, questions 2/3/6 and the
-- combined file's Part 3 SKILL). Real invalid states the database now
-- makes impossible:
-- =====================================================================

-- Money: a negative price is a real-world-impossible state (Step 3 Q2).
ALTER TABLE "Listing" ADD CONSTRAINT price_non_negative
  CHECK ("priceMinor" >= 0);

ALTER TABLE "Order" ADD CONSTRAINT order_price_non_negative
  CHECK ("priceMinorAtOrder" >= 0);

-- Order state machine value set (Step 3 Q3); the transitions between
-- them are app-level, stated honestly in Part A. CHECK cannot validate
-- a transition across an UPDATE, only the row's current value.
ALTER TABLE "Order" ADD CONSTRAINT valid_status
  CHECK (status IN ('pending', 'paid', 'shipped', 'completed', 'cancelled'));

-- Listing status value set (Step 3 Q3).
ALTER TABLE "Listing" ADD CONSTRAINT listing_status_valid
  CHECK (status IN ('active', 'sold', 'removed'));

-- Rating must be a real 1..5 verdict (Step 2, Review).
ALTER TABLE "Review" ADD CONSTRAINT rating_valid
  CHECK (rating >= 1 AND rating <= 5);

-- An account that is neither buyer nor seller is impossible (Step 2, User).
ALTER TABLE "User" ADD CONSTRAINT user_has_role
  CHECK ("isBuyer" OR "isSeller");

-- A category that is its own parent is impossible (Step 3 Q6). Cross-row
-- cycles (A -> B -> A) are NOT blocked by a plain CHECK; app-guarded.
ALTER TABLE "Category" ADD CONSTRAINT category_not_own_parent
  CHECK (id <> "parentId");

-- A transfer where the owner did not change is a meaningless no-op event
-- (Step 3 Q6, ListingOwnershipTransfer).
ALTER TABLE "ListingOwnershipTransfer" ADD CONSTRAINT transfer_changes_owner
  CHECK ("previousSellerId" <> "newSellerId");

-- =====================================================================
-- Purpose-built indexes for the ownership-history "complete ownership
-- history of this seller" reads (Step 3 Q7). The composite
-- (listingId, transferredAt) index above serves the time-window lookup.
-- =====================================================================
CREATE INDEX "ListingOwnershipTransfer_previousSellerId_idx" ON "ListingOwnershipTransfer"("previousSellerId");
CREATE INDEX "ListingOwnershipTransfer_newSellerId_idx" ON "ListingOwnershipTransfer"("newSellerId");
