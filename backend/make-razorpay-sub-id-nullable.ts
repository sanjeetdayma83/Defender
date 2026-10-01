import { prisma } from "./src/config/prisma.js";

async function main() {
  console.log("===== BEFORE =====");

  const before = await prisma.$queryRawUnsafe(`
    SELECT
      column_name,
      is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'BillingSubscription'
      AND column_name = 'razorpaySubId'
  `);

  console.table(before);

  console.log("===== ALTERING COLUMN =====");

  await prisma.$executeRawUnsafe(`
    ALTER TABLE "BillingSubscription"
    ALTER COLUMN "razorpaySubId" DROP NOT NULL
  `);

  console.log("===== AFTER =====");

  const after = await prisma.$queryRawUnsafe(`
    SELECT
      column_name,
      is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'BillingSubscription'
      AND column_name = 'razorpaySubId'
  `);

  console.table(after);

  console.log("===== EXISTING SUBSCRIPTIONS =====");

  const subscriptions = await prisma.$queryRawUnsafe(`
    SELECT
      "id",
      "companyId",
      "razorpaySubId",
      plan::text AS plan,
      status,
      "currentPeriodStart",
      "currentPeriodEnd"
    FROM "BillingSubscription"
    ORDER BY "createdAt" DESC
  `);

  console.dir(subscriptions, { depth: null });
}

main()
  .catch((error) => {
    console.error("SCHEMA CHANGE FAILED");
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
