import "dotenv/config";
import pg from "pg";

const { Client } = pg;

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL is not configured.");
}

const client = new Client({ connectionString });

async function main() {
  await client.connect();

  try {
    console.log("\n===== ENUM TYPES =====");

    const enums = await client.query(`
      SELECT
        n.nspname AS schema_name,
        t.typname AS enum_name,
        string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS values
      FROM pg_type t
      JOIN pg_enum e
        ON t.oid = e.enumtypid
      JOIN pg_namespace n
        ON n.oid = t.typnamespace
      WHERE n.nspname = 'public'
      GROUP BY n.nspname, t.typname
      ORDER BY t.typname
    `);

    console.table(enums.rows);

    console.log("\n===== PRIMARY / UNIQUE CONSTRAINTS =====");

    const constraints = await client.query(`
      SELECT
        tc.table_name,
        tc.constraint_name,
        tc.constraint_type,
        string_agg(
          kcu.column_name,
          ', '
          ORDER BY kcu.ordinal_position
        ) AS columns
      FROM information_schema.table_constraints tc
      LEFT JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
       AND tc.table_schema = kcu.table_schema
       AND tc.table_name = kcu.table_name
      WHERE tc.table_schema = 'public'
        AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
        AND tc.table_name IN (
          'Company',
          'User',
          'Warehouse',
          'Order',
          'MarketplaceAccount',
          'Recording',
          'RecordingSegment',
          'Evidence',
          'Claim',
          'Return',
          'Session',
          'Station',
          'AuditLog',
          'BillingSubscription',
          'BillingPayment',
          'BillingWebhookEvent',
          'InviteToken',
          'Notification',
          'order_identifiers',
          'scan_transactions',
          'scan_wallets'
        )
      GROUP BY
        tc.table_name,
        tc.constraint_name,
        tc.constraint_type
      ORDER BY
        tc.table_name,
        tc.constraint_type,
        tc.constraint_name
    `);

    console.table(constraints.rows);

    console.log("\n===== FOREIGN KEYS =====");

    const foreignKeys = await client.query(`
      SELECT
        tc.table_name,
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS referenced_table,
        ccu.column_name AS referenced_column
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
       AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
       AND tc.table_schema = ccu.constraint_schema
      WHERE tc.table_schema = 'public'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name IN (
          'Company',
          'User',
          'Warehouse',
          'Order',
          'MarketplaceAccount',
          'Recording',
          'RecordingSegment',
          'Evidence',
          'Claim',
          'Return',
          'Session',
          'Station',
          'AuditLog',
          'BillingSubscription',
          'BillingPayment',
          'BillingWebhookEvent',
          'InviteToken',
          'Notification',
          'order_identifiers',
          'scan_transactions',
          'scan_wallets'
        )
      ORDER BY
        tc.table_name,
        tc.constraint_name,
        kcu.ordinal_position
    `);

    console.table(foreignKeys.rows);

    console.log("\n===== ALL LEGACY TABLE COLUMNS =====");

    const columns = await client.query(`
      SELECT
        table_name,
        ordinal_position,
        column_name,
        data_type,
        udt_name,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name IN (
          'Company',
          'User',
          'Warehouse',
          'Order',
          'MarketplaceAccount',
          'Recording',
          'RecordingSegment',
          'Evidence',
          'Claim',
          'Return',
          'Session',
          'Station',
          'AuditLog',
          'BillingSubscription',
          'BillingPayment',
          'BillingWebhookEvent',
          'InviteToken',
          'Notification',
          'order_identifiers',
          'scan_transactions',
          'scan_wallets'
        )
      ORDER BY
        table_name,
        ordinal_position
    `);

    console.table(columns.rows);

    console.log("\n===== ROW COUNTS =====");

    const tableNames = [
      "Company",
      "User",
      "Warehouse",
      "Order",
      "MarketplaceAccount",
      "Recording",
      "RecordingSegment",
      "Evidence",
      "Claim",
      "Return",
      "Session",
      "Station",
      "AuditLog",
      "BillingSubscription",
      "BillingPayment",
      "BillingWebhookEvent",
      "InviteToken",
      "Notification",
      "order_identifiers",
      "scan_transactions",
      "scan_wallets",
    ];

    for (const table of tableNames) {
      const result = await client.query(
        `SELECT COUNT(*)::bigint AS count FROM "${table}"`
      );

      console.log(`${table}: ${result.rows[0].count}`);
    }

  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("\n===== DATABASE INSPECTION FAILED =====");
  console.error(error);
  process.exit(1);
});
