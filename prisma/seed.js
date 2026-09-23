const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const crypto = require('crypto');

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

// Non-sequential human-facing reference: EKE- + 8 random Crockford base-32 chars (Q5).
const BASE32 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
function ekeCode() {
  let out = '';
  for (let i = 0; i < 8; i++) out += BASE32[crypto.randomInt(32)];
  return 'EKE-' + out;
}
function ekeIdemKey() {
  return crypto.randomBytes(16).toString('hex');
}

// Deterministic timestamps for the ownership-transfer scenario, so the
// order.createdAt provably falls inside seller A's ownership window and the
// transfer (transferredAt) provably happens after the order was placed.
const NOW = Date.now();
const T_LISTING = new Date(NOW - 10 * 24 * 3600 * 1000); // 10 days ago
const T_ORDER = new Date(NOW - 3 * 24 * 3600 * 1000); // 3 days ago
const T_TRANSFER = new Date(NOW - 2 * 24 * 3600 * 1000); // 2 days ago

async function main() {
  // Wipe clean for re-runnable seeding (no foreign keys referenced yet).
  await prisma.review.deleteMany();
  await prisma.order.deleteMany();
  await prisma.listingOwnershipTransfer.deleteMany();
  await prisma.listing.deleteMany();
  await prisma.category.deleteMany();
  await prisma.user.deleteMany();

  // --- Users ---------------------------------------------------------------
  const ada = await prisma.user.create({
    data: { email: 'ada@example.com', fullName: 'Ada Okafor', isBuyer: true },
  });
  const nkechi = await prisma.user.create({
    data: { email: 'nkechi@example.com', fullName: 'Nkechi Eze', isSeller: true },
  });
  const obi = await prisma.user.create({
    data: { email: 'obi@example.com', fullName: 'Obi Nwosu', isSeller: true },
  });
  const emeka = await prisma.user.create({
    data: {
      email: 'emeka@example.com',
      fullName: 'Emeka Okoye',
      isBuyer: true,
      isSeller: true, // buyer AND seller — both flags, explicitly allowed
    },
  });
  console.log('users:', { ada: ada.id, nkechi: nkechi.id, obi: obi.id, emeka: emeka.id });

  // --- Category tree (self-referential) ------------------------------------
  const produce = await prisma.category.create({ data: { name: 'Produce' } });
  const electronics = await prisma.category.create({ data: { name: 'Electronics' } });
  const yam = await prisma.category.create({
    data: { name: 'Yam', parentId: produce.id },
  });
  const pepper = await prisma.category.create({
    data: { name: 'Pepper', parentId: produce.id },
  });
  const phones = await prisma.category.create({
    data: { name: 'Phones', parentId: electronics.id },
  });
  const accessories = await prisma.category.create({
    data: { name: 'Accessories', parentId: electronics.id },
  });
  console.log('categories:', { produce, electronics, yam, pepper, phones, accessories });

  // --- Listings (across categories, sellers, and statuses) -----------------
  const yamListing = await prisma.listing.create({
    data: {
      sellerId: nkechi.id,
      categoryId: yam.id,
      title: 'Organic yam tubers, 3 pieces',
      description: 'Freshly harvested white yam, from Nsukka.',
      priceMinor: 150000, // = ₦1,500.00
      currency: 'NGN',
      status: 'active',
      imageUrls: ['https://cdn.example.com/yam-1.jpg'],
      createdAt: T_LISTING,
    },
  });
  const pepperListing = await prisma.listing.create({
    data: {
      sellerId: obi.id,
      categoryId: pepper.id,
      title: 'Scotch bonnet peppers, bunch',
      description: 'Hot peppers, market-fresh today.',
      priceMinor: 2500, // = ₦25.00
      currency: 'NGN',
      status: 'active',
      imageUrls: [],
      createdAt: T_LISTING,
    },
  });
  const phoneListing = await prisma.listing.create({
    data: {
      sellerId: nkechi.id,
      categoryId: phones.id,
      title: 'Refurbished Android phone',
      description: 'Works perfectly, minor screen mark.',
      priceMinor: 4500000, // = ₦45,000.00
      currency: 'NGN',
      status: 'active',
      imageUrls: ['https://cdn.example.com/phone-1.jpg'],
      createdAt: T_LISTING,
    },
  });
  const chargerListing = await prisma.listing.create({
    data: {
      sellerId: emeka.id,
      categoryId: accessories.id,
      title: 'USB-C fast charger',
      description: '65W GaN charger, 2 ports.',
      priceMinor: 15000, // = ₦150.00
      currency: 'NGN',
      status: 'sold', // exercises a non-default status
      imageUrls: [],
      createdAt: T_LISTING,
    },
  });

  // The listing that will CHANGE OWNERSHIP (the confirmed bonus scenario):
  // owned by seller A (nkechi) at seed time, order placed while A owns it,
  // then transferred to seller B (obi) — write-first, in one transaction.
  const basketListing = await prisma.listing.create({
    data: {
      sellerId: nkechi.id, // A
      categoryId: accessories.id,
      title: 'Hand-woven raffia basket',
      description: 'Woven by hand, reinforced rim.',
      priceMinor: 50000, // = ₦500.00
      currency: 'NGN',
      status: 'active',
      imageUrls: ['https://cdn.example.com/basket-1.jpg'],
      createdAt: T_LISTING,
    },
  });

  // --- Orders (multiple statuses, snapshots frozen from listings) ----------
  const oCompleted = await prisma.order.create({
    data: {
      orderCode: ekeCode(),
      idempotencyKey: ekeIdemKey(),
      buyerId: ada.id,
      listingId: yamListing.id,
      titleAtOrder: yamListing.title,
      priceMinorAtOrder: yamListing.priceMinor,
      currencyAtOrder: yamListing.currency,
      shippingAddressAtOrder: '12 Market Road, Enugu',
      status: 'completed',
      createdAt: new Date(NOW - 6 * 24 * 3600 * 1000),
    },
  });
  const oShipped = await prisma.order.create({
    data: {
      orderCode: ekeCode(),
      idempotencyKey: ekeIdemKey(),
      buyerId: ada.id,
      listingId: pepperListing.id,
      titleAtOrder: pepperListing.title,
      priceMinorAtOrder: pepperListing.priceMinor,
      currencyAtOrder: pepperListing.currency,
      shippingAddressAtOrder: '12 Market Road, Enugu',
      status: 'shipped',
      createdAt: new Date(NOW - 5 * 24 * 3600 * 1000),
    },
  });
  const oPaid = await prisma.order.create({
    data: {
      orderCode: ekeCode(),
      idempotencyKey: ekeIdemKey(),
      buyerId: ada.id,
      listingId: phoneListing.id,
      titleAtOrder: phoneListing.title,
      priceMinorAtOrder: phoneListing.priceMinor,
      currencyAtOrder: phoneListing.currency,
      shippingAddressAtOrder: '12 Market Road, Enugu',
      status: 'paid',
      createdAt: new Date(NOW - 4 * 24 * 3600 * 1000),
    },
  });
  const oPending = await prisma.order.create({
    data: {
      orderCode: ekeCode(),
      idempotencyKey: ekeIdemKey(),
      buyerId: emeka.id,
      listingId: chargerListing.id,
      titleAtOrder: chargerListing.title,
      priceMinorAtOrder: chargerListing.priceMinor,
      currencyAtOrder: chargerListing.currency,
      shippingAddressAtOrder: '3 Old Market Lane, Onitsha',
      status: 'pending',
      createdAt: new Date(NOW - 24 * 3600 * 1000),
    },
  });

  // THE BONUS ORDER: placed against basketListing at T_ORDER, while A
  // (nkechi) still owned it. This is the order whose TRUE historical seller
  // must resolve to A, even though the listing is transferred to B afterward.
  const oBasket = await prisma.order.create({
    data: {
      orderCode: ekeCode(),
      idempotencyKey: ekeIdemKey(),
      buyerId: ada.id,
      listingId: basketListing.id,
      titleAtOrder: basketListing.title,
      priceMinorAtOrder: basketListing.priceMinor,
      currencyAtOrder: basketListing.currency,
      shippingAddressAtOrder: '12 Market Road, Enugu',
      status: 'paid',
      createdAt: T_ORDER,
    },
  });
  console.log('bonus order placed at:', T_ORDER.toISOString(), 'while nkechi (A) owned the basket');

  // --- Ownership transfer (write-first, one transaction) -------------------
  // 1) INSERT the ListingOwnershipTransfer row FIRST
  // 2) THEN update Listing.sellerId to B — same transaction, before the
  //    Listing update completes, so history always precedes the present.
  await prisma.$transaction([
    prisma.listingOwnershipTransfer.create({
      data: {
        listingId: basketListing.id,
        previousSellerId: nkechi.id, // A
        newSellerId: obi.id, // B
        transferredAt: T_TRANSFER,
      },
    }),
    prisma.listing.update({
      where: { id: basketListing.id },
      data: { sellerId: obi.id }, // B now owns it today
    }),
  ]);
  console.log(
    'basket transferred A->B at:',
    T_TRANSFER.toISOString(),
    '| current Listing.sellerId is now:',
    (await prisma.listing.findUniqueOrThrow({ where: { id: basketListing.id } })).sellerId,
  );

  // --- Review (one per completed order, about the SELLER) ------------------
  await prisma.review.create({
    data: {
      orderId: oCompleted.id,
      sellerId: nkechi.id, // fixed subject: the historical seller of oCompleted
      rating: 5,
      comment: 'Yams were fresh and exactly as described.',
      sellerResponse: 'Thank you — enjoy the yam!',
    },
  });
  console.log('review on', oCompleted.orderCode, 'rating 5 about nkechi (the seller)');

  // Proof audit: the transfer lookup inputs for the 6th query.
  console.log('BONUS_LOOKUP listingId=', basketListing.id);
  console.log('BONUS_LOOKUP orderCreatedAt=', T_ORDER.toISOString());
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());