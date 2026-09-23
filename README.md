# eke-market-day

Task 3 of the Five Engineering Tasks — **API Design and Data Modeling.**

A marketplace API design and data model: buyers, sellers, listings,
orders, reviews. Graded primarily on the **written document**, not on
running code — a small schema implementation in Part B only proves the
model holds.

"Eke" is one of the four traditional Igbo market days; the folder/package
name is `eke-market-day`, while the in-app display name is
**"EKE (market day)"**.

Stack planned: **Next.js + Prisma + PostgreSQL (local Docker)** — matching
every other project built tonight.

- Full design: [DOCUMENTATION.md](./DOCUMENTATION.md)
- Governing spec (PRD + AGENT_RULES + SKILL): [EKE-MARKET-DAY-COMBINED.md](./EKE-MARKET-DAY-COMBINED.md)

## Status

The written design (Part A) is complete and reflects the confirmed
decisions: the `ListingOwnershipTransfer` history table, `Category` as a
real entity, and the mandatory money `CHECK >= 0` constraints.

**Part B is complete and proven with real output.** Prisma schema
(all six entities), a real migration with every raw-SQL CHECK
constraint, a genuine seed (including an ownership transfer), the five
proof queries, `EXPLAIN ANALYZE` confirming index use on the two
heaviest, the confirmed 6th bonus query (proving the historical-seller
lookup returns the original seller), and all three invalid inserts
genuinely rejected by the database. SQL lives in `sql/`, the seed in
`prisma/seed.js`.

## How to run

```
npm install
docker compose up -d          # Postgres on host port 5435
npx prisma migrate dev        # applies the real migration + constraints
npx prisma db seed            # loads the proof dataset
```

The five proof queries, two EXPLAINs, bonus query, and three invalid
inserts are each self-contained SQL files in `sql/`:

- `p1_seller_creates_listing.sql` … `p5_order_history.sql`
- `explain_action3_seller_fulfill.sql`, `explain_action5_buyer_history.sql`
- `p6_bonus_historical_seller.sql`  (the corrected 3-branch lookup)
- `invalid1_review_no_order.sql`, `invalid2_order_nonexistent_listing.sql`, `invalid3_negative_money.sql`

Run one with:

```
Get-Content sql\p1_seller_creates_listing.sql -Raw | docker exec -i eke-market-day-postgres psql -U eke -d eke_market_day -v ON_ERROR_STOP=1
```

## Secrets

No real credentials exist in this project. The local dev database uses
trust auth (no password) on host port 5435; `.env` holds only the local
`DATABASE_URL`, is created by hand, and is gitignored before any commit.