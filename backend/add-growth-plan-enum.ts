import { prisma } from "./src/config/prisma.js";

async function main() {
  console.log("===== ADDING GROWTH TO LIVE PLAN ENUM =====");

  await prisma.$executeRawUnsafe(`
    ALTER TYPE "Plan"
    ADD VALUE IF NOT EXISTS 'growth';
  `);

  console.log("Growth enum value added/verified successfully.");

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

  console.log("===== LIVE PLAN ENUM AFTER CHANGE =====");
  console.table(enumValues);
}

main()
  .catch((error) => {
    console.error("FAILED TO ADD GROWTH ENUM VALUE");
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
