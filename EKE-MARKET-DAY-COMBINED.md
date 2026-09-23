# EKE-MARKET-DAY — Combined PRD + AGENT_RULES + SKILL

## Task
Task 3 of the Five Engineering Tasks brief: API Design and Data
Modeling. Time budget: 10–14 hours. UNLIKE Tasks 1 and 2, this is
graded on the DOCUMENT, not running code. A small schema
implementation proves the model holds, but the real deliverable is
the design itself, written down, complete, and defensible.

Project name: **eke-market-day** — "Eke" is one of the four
traditional Igbo market days (Eke, Orie, Afọ, Nkwọ), the real, still
in-use word for "market day," a deliberate name for a marketplace
project, chosen and confirmed by the user.

**Display name vs. project name:** the folder/package name is
lowercase, hyphenated `eke-market-day` (npm/filesystem naming rule).
The actual, user-facing display name shown in the app itself (page
title, header, any branding text) is **"EKE (market day)"** —
exactly as the user specified. These are two separate things; do not
confuse or merge them.

Domain chosen: a marketplace — buyers, sellers, listings, orders,
reviews. A product genuinely not built elsewhere tonight, real
complexity, matching the brief's own suggested example.

---

## PART 1 — PRD

### What This Is
A complete API design and data model for a marketplace product,
done to the standard a senior engineer would expect before a single
line of implementation code gets written. Then a small, real proof
that the model actually holds under real constraints.

### Step 1 — Requirements (one page, written first)
What the product does. Who uses it. The five most important actions
a user takes. Every later design decision must trace back to
something on this page. Real candidates for the five actions: a
seller creates a listing; a buyer places an order; a seller marks an
order shipped/fulfilled; a buyer leaves a review after a completed
order; a buyer or seller views their own order history.

### Step 2 — Entities and Relationships
Every entity: one-sentence description, fields with real types,
required flags, identifier shape (generated, never sequential).
Real relationships with explicit cardinality (one-to-one,
one-to-many, many-to-many). A real diagram, hand-drawn and
photographed is acceptable, a tool-made one is better.

Minimum real entity set: User (can be buyer, seller, or both —
decide and state how this is modeled), Listing (belongs to a
seller), Category (self-referential tree — a category can have a
parent category, for real, nested browsing; Listing references
Category), Order (belongs to a buyer, references a Listing — seller-
of-order is derived, see the ListingOwnershipTransfer note below,
never stored directly on Order), OrderItem (if an order can contain
more than one listing — decide and state whether it can), Review
(belongs to a completed Order, written by the buyer, about the
seller or the listing — decide which and state why).

**CONFIRMED DECISION — ListingOwnershipTransfer table (user's own
choice, stick to this exactly):** rather than snapshotting sellerId
directly onto Order, or leaving "current seller" as a simple, always-
live lookup, this design adds a real, explicit history table:
`ListingOwnershipTransfer` (id, listingId, previousSellerId,
newSellerId, transferredAt). Every time a listing's ownership
changes, a new row is written here FIRST, before Listing.sellerId
itself is updated — this is a genuine, permanent audit trail. To
find the true, historically-correct seller of any given Order, the
real query is: find the ownership-transfer row for that listingId
whose transferredAt window actually contains the Order's own
createdAt timestamp (i.e. the seller who owned the listing at the
moment this specific order was actually placed, not whoever owns it
today). This is a deliberate, considered choice over the simpler
alternative (snapshotting sellerId directly on Order like D1 does
for price/title) — it costs real query complexity, but genuinely
preserves full ownership history as its own, real feature, not just
"who sold this one order." State this reasoning explicitly in the
written document's Step 1 (Normalization) answer.

### Step 3 — The Seven Hard Questions (answered in writing, this is
where the grade is actually earned)

1. **Normalization.** Where does each fact live, once, canonically?
   Find at least two places worth deliberately denormalizing, and
   justify each with a real reason (e.g. does an Order snapshot the
   listing's price and title at time of purchase, so it stays
   correct even if the seller edits the listing later — yes, this
   is the standard, correct choice, and the PRD must say why).
   Separately, and distinctly: seller identity for an Order is NOT
   denormalized this way. The confirmed design (Step 2) instead adds
   a real ListingOwnershipTransfer history table rather than
   snapshotting sellerId onto Order — state this as the real answer
   to "where does the canonical fact of who-sold-this-order live,"
   and explain honestly why this was chosen over the simpler
   snapshot alternative (preserves full ownership history as its own
   real feature, at the real cost of a more complex lookup query).
2. **Money.** Every monetary field is a whole integer in minor units
   (kobo, cents), with a currency column beside it. State this rule,
   apply it everywhere money appears. A real `CHECK >= 0` constraint
   is REQUIRED on every monetary column, not optional — a negative
   price or a negative order total is a genuinely invalid,
   real-world-impossible state, and the database itself must make it
   impossible, not just the application layer.
3. **Status and state machines.** Orders have a real lifecycle. Draw
   the full state machine: every status, every allowed transition,
   every forbidden one (e.g. `completed` can never go back to
   `pending`). State plainly what, in the real implementation, would
   enforce this (a database check constraint, or application logic —
   pick one and justify it).
4. **Time.** Every entity has `createdAt`/`updatedAt`. Decide,
   per-entity, whether it's soft-deleted (`deletedAt`) or
   hard-deleted, and why, referencing real compliance/audit
   reasoning where relevant (e.g. Orders should likely never be
   hard-deleted, for dispute/audit reasons). **User specifically must
   be soft-deleted, not hard-deleted, and this is now load-bearing
   for a second, real reason beyond general compliance**: the
   confirmed ListingOwnershipTransfer table stores real
   previousSellerId/newSellerId references to User rows. If a User
   were ever genuinely hard-deleted, those historical references
   would break, and the true, historical seller of an old order could
   no longer be looked up. State this explicit dependency in the
   written answer, not just "soft delete for compliance reasons."
5. **Identifiers.** Generated (cuid/uuid), never sequential. State
   the real, security reason why (enumeration risk).
6. **Constraints.** Per table: unique constraints, foreign keys,
   check constraints. For each, state plainly which invalid,
   real-world-impossible state it makes impossible for the database
   itself to ever hold (e.g. a Review cannot exist without a
   completed Order — name the actual constraint that enforces this).
   Include ListingOwnershipTransfer explicitly: foreign keys on
   listingId, previousSellerId, and newSellerId (each referencing a
   real, existing row); state plainly what real, invalid state this
   makes impossible (an ownership record pointing at a listing or
   user that was never real).
7. **Indexes.** For each of the five real, important actions from
   Step 1, name the actual index that would serve that specific
   query efficiently. Also name the specific, real index needed for
   ListingOwnershipTransfer's own core query — looking up the
   correct historical seller for a given Order requires finding the
   transfer row covering a specific point in time, so a composite
   index on (listingId, transferredAt) is the real, correct choice,
   state this explicitly.

### Step 4 — The API Design
For every one of the five important actions, and every entity's
basic CRUD operations: method + versioned path, request body (types,
required fields marked), response body, every real error it can
return with its real status code, and whether it's idempotent (and
if a mutation should be idempotent, exactly how — e.g. an
idempotency key on order creation).

Pagination/filtering/sorting contract shown on every list endpoint.

Then, two required design-question analyses, in writing:
- **Over-fetching.** Pick one real endpoint where a REST response
  would carry meaningfully more than a typical client needs. Show
  the real REST response. Show what an equivalent GraphQL query
  would look like and return instead. State plainly whether GraphQL
  is actually worth it here, and at what real point (team size,
  client diversity, query complexity) the tradeoff would flip.
- **Real-time.** Identify one real place in this product where a
  client needs updates without polling (e.g. a seller watching a new
  order come in live). State whether WebSockets or Server-Sent
  Events is the right choice, and why, based on whether the update
  flow is genuinely bidirectional or one-directional.

### Step 5 — Prove The Model Holds
Implement ONLY the schema (no real endpoints beyond what's needed to
seed/query). Write the real migration. Add every real constraint and
index designed above. Seed a small, real dataset. Write five real
queries, one per important action from Step 1. Check the real query
plan on the two heaviest, confirm the designed indexes are actually
used. Then deliberately attempt three real invalid inserts (e.g. a
Review with no Order, an Order referencing a nonexistent Listing, a
negative money value — the required CHECK >= 0 constraint from Step
3.2 must reject this, not an optional case) and show the
database genuinely rejecting each one.

**PLUS a real 6th, bonus query (confirmed decision, beyond the five
required):** none of the five important actions from Step 1 is
"look up the historical seller of an order," so the confirmed
ListingOwnershipTransfer mechanism would otherwise be fully designed
and reasoned about in writing but never actually proven to work.
Add a sixth query, using the exact SQL pattern from Part 3's SKILL
section, that: (a) seeds a listing, an order against it, THEN
transfers the listing to a new seller, (b) runs the real query and
confirms it correctly returns the ORIGINAL seller for the
already-placed order (not the new one), proving the historical
lookup genuinely works, not just exists on paper.

### Evidence Required
- The real, hand-drawn-or-tooled entity diagram.
- The real state machine diagram for at least the Order entity.
- Real query plan output showing index use on the two heaviest
  queries.
- Real screenshots of all three deliberately invalid inserts being
  rejected by the database.
- Real output from the 6th, bonus query proving the historical-
  seller lookup returns the correct, original seller after a real,
  seeded ownership transfer.

---

## PART 2 — AGENT_RULES

Same, proven, strict rules used across every project tonight, plus
one specific to this task's own nature.

### This task is graded on the document — treat it that way
The written design document (requirements, entities, the seven hard
questions, the API contract, the two analyses) is the actual,
primary deliverable. Do not rush past it to get to code. A shallow
document with perfect code is a failing submission per the brief's
own stated standard.

### Git
Never commit, stage, or push without explicit authorization. Read-
only git commands always fine. Real, descriptive commit messages,
never "update"/"fix".

### Naming
Lowercase, hyphenated, no capital letters anywhere — this broke
create-next-app once already this week.

### Secrets
Real credentials (DATABASE_URL) written into `.env` by hand, by the
user, never by you. `.env.example` gets placeholders only. Confirm
`.env` is gitignored before any commit.

### Evidence
Every "Evidence Required" item needs a real screenshot or real
command output. Never a description of expected behavior presented
as observed. The three invalid-insert rejections specifically must
be real, attempted, and shown actually failing, not asserted.

### Scope discipline
Build ONLY the schema and the five proof queries plus the confirmed
6th, bonus ownership-transfer query. Do not build a full CRUD API,
do not build a frontend, do not build authentication. This is
explicitly a document + schema task, not a working product.

### Sequencing
Requirements page → entity list/diagram → seven hard questions
(written) → API design + two analyses (written) → schema
implementation → seed → five queries + plans + the confirmed 6th,
bonus ownership-transfer query → three invalid-insert tests. Do not
implement the schema before the written design is genuinely
complete — the schema should be a direct, faithful translation of
what was already decided in writing, not the other way around.

---

## PART 3 — SKILL (technical how-to)

### Money as minor units
```prisma
model Listing {
  id            String   @id @default(cuid())
  priceMinor    Int      // e.g. 150000 = ₦1,500.00
  currency      String   @default("NGN")
}
```
Prisma's schema syntax alone cannot express a CHECK constraint —
per Step 3.2, this is now REQUIRED, not optional, so it needs a real
raw-SQL migration addition, the same pattern as the status
constraint below:
```sql
ALTER TABLE "Listing" ADD CONSTRAINT price_non_negative
  CHECK ("priceMinor" >= 0);
ALTER TABLE "Order" ADD CONSTRAINT order_price_non_negative
  CHECK ("priceMinorAtOrder" >= 0);
```

### Snapshotting price at time of order (real denormalization,
justified)
```prisma
// This example assumes the single-listing-per-order branch of the
// Step 2 decision above. If the real design instead allows multiple
// listings per order, replace listingId/priceMinorAtOrder/
// titleAtOrder here with a separate OrderItem model instead, and
// state that choice explicitly in the written document.
model Order {
  id                String   @id @default(cuid())
  buyerId           String
  buyer             User     @relation(fields: [buyerId], references: [id])
  listingId         String
  listing           Listing  @relation(fields: [listingId], references: [id])
  // Deliberately denormalized: snapshot, not a live lookup —
  // the price the buyer actually agreed to must never silently
  // change if the seller edits the listing afterward.
  priceMinorAtOrder Int
  titleAtOrder      String
  status            String   @default("pending")
}
```

### ListingOwnershipTransfer — the confirmed, real history table
```prisma
model ListingOwnershipTransfer {
  id               String   @id @default(cuid())
  listingId        String
  listing          Listing  @relation(fields: [listingId], references: [id])
  previousSellerId String
  previousSeller   User     @relation("PreviousSeller", fields: [previousSellerId], references: [id])
  newSellerId      String
  newSeller        User     @relation("NewSeller", fields: [newSellerId], references: [id])
  transferredAt    DateTime @default(now())

  @@index([listingId, transferredAt])
}
```
The real, correct query to find an Order's true, historical seller
— worth writing exactly this way, not a live lookup on Listing:
```sql
SELECT COALESCE(
  (SELECT "newSellerId" FROM "ListingOwnershipTransfer"
   WHERE "listingId" = $1 AND "transferredAt" <= $2
   ORDER BY "transferredAt" DESC LIMIT 1),
  (SELECT "sellerId" FROM "Listing" WHERE "id" = $1)
) AS historical_seller_id;
-- $1 = the order's listingId, $2 = the order's own createdAt.
-- Falls back to Listing.sellerId directly if no transfer ever
-- happened (the common case: most listings never change hands).
```

### Category — self-referential tree (a distinct real pattern)
```prisma
model Category {
  id       String     @id @default(cuid())
  name     String
  parentId String?
  parent   Category?  @relation("CategoryTree", fields: [parentId], references: [id])
  children Category[] @relation("CategoryTree")
}
```
`parentId` is nullable specifically because a top-level category
(e.g. "Electronics") has no parent at all — only a sub-category
(e.g. "Phones" under "Electronics") sets it. This is a real,
different pattern from every foreign key elsewhere in this schema,
worth naming explicitly why: it points back into its OWN table, not
a different one.

### Enforcing the order state machine with a check constraint
```sql
ALTER TABLE "Order" ADD CONSTRAINT valid_status
  CHECK (status IN ('pending', 'paid', 'shipped', 'completed', 'cancelled'));
```
Real forbidden-transition enforcement (e.g. `completed` can never
return to `pending`) typically needs application-level logic or a
trigger — a plain CHECK constraint can validate a value is in the
allowed set, but not validate a transition between two values across
an UPDATE. State this real limitation honestly in the document
rather than overclaiming what a CHECK constraint alone can do.

### Making a Review impossible without a completed Order
```prisma
model Review {
  id      String @id @default(cuid())
  orderId String @unique // one review per order, enforced
  order   Order  @relation(fields: [orderId], references: [id])
  rating  Int    // e.g. 1-5, real range worth validating with a
                 // check constraint too, not just the app layer
}
```
The real constraint worth naming explicitly in the document: the
foreign key alone stops a Review pointing at a nonexistent Order,
but "the Order must be `completed`" specifically needs an
application-level check before the Review insert — state this
honestly rather than claiming the database alone enforces it, unless
a real trigger is built to do so.

### Checking a real query plan for index use
```sql
EXPLAIN ANALYZE SELECT * FROM "Order" WHERE "buyerId" = 'some-real-id';
```
Look for `Index Scan` (good, the index is used) vs `Seq Scan` (bad,
a full table scan happened despite the index existing — worth
investigating why).

### Testing a real invalid insert deliberately
```sql
-- Should fail: Review with no matching Order
INSERT INTO "Review" ("id", "orderId", "rating") VALUES ('test1', 'nonexistent-order-id', 5);
-- Real, expected output: a foreign key violation error, captured as
-- real evidence, not paraphrased.
```
