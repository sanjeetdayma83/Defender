import { prisma } from "../src/config/prisma.js";

try {
  console.log("\n===== 1. ALL PUBLIC TABLES AND VIEWS =====");

  const tables = await prisma.$queryRaw<Array<{
    table_name: string;
    table_type: string;
  }>>`
    SELECT table_name, table_type
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_type, table_name
  `;

  for (const t of tables) {
    console.log(`${t.table_type} | public.${t.table_name}`);
  }

  console.log(`TOTAL TABLES/VIEWS: ${tables.length}`);

  console.log("\n===== 2. MIGRATION / ORM TRACKING TABLES =====");

  const tracking = tables.filter(t =>
    /migration|prisma|drizzle|knex|typeorm|sequelize/i.test(t.table_name)
  );

  if (!tracking.length) {
    console.log("No commonly named migration-tracking table found.");
  } else {
    for (const t of tracking) {
      console.log(`FOUND | public.${t.table_name} | ${t.table_type}`);
    }
  }

  console.log("\n===== 3. ALL PUBLIC ENUM TYPES =====");

  const enums = await prisma.$queryRaw<Array<{
    type_name: string;
    enum_value: string;
    sort_order: number;
  }>>`
    SELECT
      t.typname AS type_name,
      e.enumlabel AS enum_value,
      e.enumsortorder AS sort_order
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
    ORDER BY t.typname, e.enumsortorder
  `;

  for (const e of enums) {
    console.log(`${e.type_name} | ${e.enum_value}`);
  }

  console.log("\n===== 4. ALL PUBLIC FOREIGN KEYS =====");

  const foreignKeys = await prisma.$queryRaw<Array<{
    constraint_name: string;
    table_name: string;
    column_name: string;
    foreign_table: string;
    foreign_column: string;
    delete_rule: string;
  }>>`
    SELECT
      tc.constraint_name,
      tc.table_name,
      kcu.column_name,
      ccu.table_name AS foreign_table,
      ccu.column_name AS foreign_column,
      rc.delete_rule
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_catalog = kcu.constraint_catalog
      AND tc.constraint_schema = kcu.constraint_schema
      AND tc.constraint_name = kcu.constraint_name
      AND tc.table_name = kcu.table_name
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_catalog = ccu.constraint_catalog
      AND tc.constraint_schema = ccu.constraint_schema
      AND tc.constraint_name = ccu.constraint_name
    JOIN information_schema.referential_constraints rc
      ON tc.constraint_catalog = rc.constraint_catalog
      AND tc.constraint_schema = rc.constraint_schema
      AND tc.constraint_name = rc.constraint_name
    WHERE tc.constraint_schema = 'public'
      AND tc.constraint_type = 'FOREIGN KEY'
    ORDER BY tc.table_name, tc.constraint_name, kcu.ordinal_position
  `;

  for (const fk of foreignKeys) {
    console.log(
      `${fk.table_name}.${fk.column_name} -> ${fk.foreign_table}.${fk.foreign_column}` +
      ` | ON DELETE ${fk.delete_rule} | ${fk.constraint_name}`
    );
  }

  console.log(`TOTAL FOREIGN KEY COLUMNS: ${foreignKeys.length}`);
  console.log("\nREAD-ONLY CATALOG AUDIT COMPLETE");
} finally {
  await prisma.$disconnect();
}
