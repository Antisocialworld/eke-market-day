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

**Part B has not started.** No schema, migration, seed, proof queries, or
invalid-insert tests exist yet — implementation begins only after review
approval of the written design.

## Secrets

No credentials exist in this project today. When Part B begins, real
credentials (`DATABASE_URL`) are written into `.env` by hand, by the user,
never by tooling, and `.env` is gitignored before any commit.