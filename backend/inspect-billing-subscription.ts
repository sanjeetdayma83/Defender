import { prisma } from "./src/config/prisma.js";

async function main() {
  console.log("===== BILLING SUBSCRIPTION COLUMNS =====");

  const columns = await prisma.$queryRawUnsafe<
    Array<{
      column_name: string;
      data_type: string;
      udt_name: string;
      is_nullable: string;
      column_default: string | null;
    }>
  >(`
    SELECT
      column_name,
      data_type,
      udt_name,
      is_nullable,
      column_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'BillingSubscription'
    ORDER BY ordinal_position
  `);

  console.table(columns);

  console.log("===== EXISTING ROWS =====");

  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM "BillingSubscription" ORDER BY "currentPeriodStart" DESC`,
  );

  console.dir(rows, { depth: null });
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
