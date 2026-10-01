import { prisma } from "./src/config/prisma.js";

async function main() {
  const enumValues = await prisma.$queryRawUnsafe<
    Array<{ enum_value: string }>
  >(`
    SELECT e.enumlabel AS enum_value
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'Plan'
    ORDER BY e.enumsortorder;
  `);

  const companies = await prisma.$queryRawUnsafe<
    Array<{
      id: string;
      companyName: string;
      plan: string;
      status: string;
    }>
  >(`
    SELECT
      id,
      "companyName",
      plan::text AS plan,
      status::text AS status
    FROM "Company"
    ORDER BY "createdAt"
    LIMIT 20;
  `);

  const subscriptions = await prisma.$queryRawUnsafe<
    Array<{
      id: string;
      companyId: string;
      razorpaySubId: string | null;
      plan: string;
      status: string;
    }>
  >(`
    SELECT
      id,
      "companyId",
      "razorpaySubId",
      plan::text AS plan,
      status::text AS status
    FROM "BillingSubscription"
    ORDER BY "createdAt" DESC
    LIMIT 20;
  `);

  console.log("===== LIVE PLAN ENUM =====");
  console.table(enumValues);

  console.log("===== LIVE COMPANIES =====");
  console.table(companies);

  console.log("===== LIVE BILLING SUBSCRIPTIONS =====");
  console.table(subscriptions);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
