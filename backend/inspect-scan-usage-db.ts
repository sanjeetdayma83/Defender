import { prisma } from "./src/config/prisma.js";

async function main() {
  const rows = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND (
        table_name ILIKE '%scan%'
        OR table_name ILIKE '%wallet%'
        OR table_name ILIKE '%usage%'
        OR table_name ILIKE '%credit%'
      )
    ORDER BY table_name
    `,
  );

  console.log("===== POSSIBLE USAGE TABLES =====");
  console.table(rows);

  const enumRows = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      t.typname AS enum_name,
      e.enumlabel AS value
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname ILIKE '%scan%'
       OR t.typname ILIKE '%wallet%'
       OR t.typname ILIKE '%usage%'
    ORDER BY t.typname, e.enumsortorder
    `,
  );

  console.log("===== POSSIBLE USAGE ENUMS =====");
  console.table(enumRows);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
