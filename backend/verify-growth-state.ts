import { prisma } from "./src/config/prisma.js";

async function main() {
  const enumValues = await prisma.$queryRawUnsafe<
    Array<{ enum_value: string; sort_order: number }>
  >(`
    SELECT
      e.enumlabel AS enum_value,
      e.enumsortorder AS sort_order
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'Plan'
      AND n.nspname = 'public'
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
    ORDER BY "createdAt";
  `);

  const subscriptions = await prisma.$queryRawUnsafe<
    Array<{
      companyId: string;
      plan: string;
      status: string;
    }>
  >(`
    SELECT
      "companyId",
      plan::text AS plan,
      status::text AS status
    FROM "BillingSubscription"
    ORDER BY "createdAt";
  `);

  console.table(enumValues);
  console.log("===== COMPANIES =====");
  console.table(companies);
  console.log("===== BILLING SUBSCRIPTIONS =====");
  console.table(subscriptions);
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
