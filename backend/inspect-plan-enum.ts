import { prisma } from "./src/config/prisma.js";

async function main() {
  console.log("===== POSTGRES VERSION =====");

  const version = await prisma.$queryRawUnsafe<
    Array<{ version: string }>
  >(`SELECT version();`);

  console.table(version);

  console.log("===== PLAN ENUM =====");

  const enumValues = await prisma.$queryRawUnsafe<
    Array<{
      enum_value: string;
      sort_order: number;
    }>
  >(`
    SELECT
      e.enumlabel AS enum_value,
      e.enumsortorder AS sort_order
    FROM pg_type t
    JOIN pg_enum e
      ON t.oid = e.enumtypid
    JOIN pg_namespace n
      ON n.oid = t.typnamespace
    WHERE t.typname = 'Plan'
      AND n.nspname = 'public'
    ORDER BY e.enumsortorder;
  `);

  console.table(enumValues);

  console.log("===== COLUMNS USING Plan ENUM =====");

  const planColumns = await prisma.$queryRawUnsafe<
    Array<{
      table_name: string;
      column_name: string;
      data_type: string;
      column_default: string | null;
    }>
  >(`
    SELECT
      c.table_name,
      c.column_name,
      c.data_type,
      c.column_default
    FROM information_schema.columns c
    WHERE c.udt_name = 'Plan'
    ORDER BY c.table_name, c.column_name;
  `);

  console.table(planColumns);

  console.log("===== PLAN VALUES IN COMPANY =====");

  const companyPlans = await prisma.$queryRawUnsafe<
    Array<{
      plan: string;
      company_count: bigint;
    }>
  >(`
    SELECT
      plan::text AS plan,
      COUNT(*) AS company_count
    FROM "Company"
    GROUP BY plan
    ORDER BY plan;
  `);

  console.table(
    companyPlans.map((row) => ({
      plan: row.plan,
      company_count: Number(row.company_count),
    })),
  );

  console.log("===== PLAN VALUES IN BILLING SUBSCRIPTION =====");

  const subscriptionPlans = await prisma.$queryRawUnsafe<
    Array<{
      plan: string;
      subscription_count: bigint;
    }>
  >(`
    SELECT
      plan::text AS plan,
      COUNT(*) AS subscription_count
    FROM "BillingSubscription"
    GROUP BY plan
    ORDER BY plan;
  `);

  console.table(
    subscriptionPlans.map((row) => ({
      plan: row.plan,
      subscription_count: Number(row.subscription_count),
    })),
  );

  console.log("===== EXISTING PROFESSIONAL DATA =====");

  const professionalCompanies = await prisma.$queryRawUnsafe<
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
    WHERE plan::text = 'professional'
    ORDER BY "createdAt";
  `);

  console.table(professionalCompanies);
}

main()
  .catch((error) => {
    console.error("READ-ONLY PLAN INSPECTION FAILED");
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
