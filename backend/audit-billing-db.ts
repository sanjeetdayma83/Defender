import { prisma } from "./src/config/prisma.js";

const tables = [
  "plans",
  "plan_features",
  "subscriptions",
  "subscription_entitlements",
  "extra_scan_packs",
  "retention_options",
  "billing_webhook_events",
  "payments",
  "payment_items",
  "billing_profiles",
  "invoices",
  "invoice_sequences",
  "invoice_items",
];

for (const table of tables) {
  console.log(`\n===== ${table} =====`);

  const columns = await prisma.$queryRawUnsafe(`
    SELECT
      column_name,
      data_type,
      is_nullable,
      column_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = '${table}'
    ORDER BY ordinal_position
  `);

  console.log("COLUMNS:");
  console.log(JSON.stringify(columns, null, 2));

  const indexes = await prisma.$queryRawUnsafe(`
    SELECT
      indexname,
      indexdef
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = '${table}'
    ORDER BY indexname
  `);

  console.log("INDEXES:");
  console.log(JSON.stringify(indexes, null, 2));
}

await prisma.$disconnect();
