import "dotenv/config";
import pg from "pg";

const { Client } = pg;

const client = new Client({
  connectionString: process.env.DATABASE_URL,
});

try {
  await client.connect();

  console.log("\n===== CONNECTION =====");

  const c = await client.query(`
    SELECT
      current_database() AS database,
      current_user AS user,
      version() AS version
  `);

  console.table(c.rows);

  console.log("\n===== PRISMA MIGRATIONS =====");

  const migrations = await client.query(`
    SELECT
      migration_name,
      finished_at,
      rolled_back_at,
      applied_steps_count
    FROM "_prisma_migrations"
    ORDER BY started_at
  `);

  console.table(migrations.rows);

  console.log("\n===== EXISTING PUBLIC TABLES =====");

  const tables = await client.query(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name
  `);

  console.table(tables.rows);

  console.log("\n===== LOSS DEFENDER CORE TABLE CHECK =====");

  const required = [
    'companies',
    'users',
    'warehouses',
    'products',
    'product_variants',
    'barcode_aliases',
    'orders',
    'order_items',
    'shipments',
    'shipment_barcodes',
    'packing_sessions',
    'evidence_media',
    'plans',
    'subscriptions',
    'scan_wallets',
    'scan_transactions',
    'payments',
    'payment_items',
    'billing_profiles',
    'invoices',
    'invoice_items',
    'invoice_sequences',
    'audit_logs',
    'storage_objects',
    'storage_usage_events'
  ];

  const result = [];

  for (const table of required) {
    const q = await client.query(
      `
      SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = $1
      ) AS exists
      `,
      [table]
    );

    result.push({
      table,
      exists: q.rows[0].exists
    });
  }

  console.table(result);

  console.log("\n===== PRISMA MIGRATION TABLE COLUMNS =====");

  const cols = await client.query(`
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = '_prisma_migrations'
    ORDER BY ordinal_position
  `);

  console.table(cols.rows);

} catch (error) {
  console.error("\nDATABASE AUDIT FAILED:");
  console.error(error);
  process.exitCode = 1;
} finally {
  await client.end().catch(() => {});
}
