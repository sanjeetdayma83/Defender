import "dotenv/config";
import pg from "pg";

const { Client } = pg;

async function main() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  await client.connect();

  try {
    console.log("\n===== TARGET SCHEMA COMPATIBILITY AUDIT =====\n");

    console.log("===== CURRENT TARGET TABLES =====");

    const targetTables = await client.query(`
      SELECT
        table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name IN (
          'companies',
          'users',
          'warehouses',
          'marketplace_accounts',
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
          'scan_transactions'
        )
      ORDER BY table_name
    `);

    console.table(targetTables.rows);

    console.log("\n===== LEGACY TABLES =====");

    const legacyTables = await client.query(`
      SELECT
        table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name IN (
          'Company',
          'User',
          'Warehouse',
          'Order',
          'Recording',
          'RecordingSegment',
          'Evidence',
          'order_identifiers',
          'scan_wallets',
          'scan_transactions'
        )
      ORDER BY table_name
    `);

    console.table(legacyTables.rows);

    console.log("\n===== ENUM / TYPE COLLISION AUDIT =====");

    const enumTypes = await client.query(`
      SELECT
        n.nspname AS schema_name,
        t.typname AS type_name,
        string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS values
      FROM pg_type t
      JOIN pg_namespace n
        ON n.oid = t.typnamespace
      JOIN pg_enum e
        ON e.enumtypid = t.oid
      WHERE n.nspname = 'public'
      GROUP BY n.nspname, t.typname
      ORDER BY t.typname
    `);

    console.table(enumTypes.rows);

    console.log("\n===== CURRENT PRISMA ENUM NAMES =====");

    const prismaEnumNames = [
      "UserRole",
      "Marketplace",
      "OrderStatus",
      "ShipmentStatus",
      "PackingSessionStatus",
      "EvidenceStatus",
      "MediaType",
      "BillingSubscriptionStatus",
      "BillingPaymentStatus",
      "BillingWebhookStatus",
      "ScanTransactionType",
      "ScanTransactionStatus",
      "PlanCode",
    ];

    for (const name of prismaEnumNames) {
      const exists = enumTypes.rows.find((r) => r.type_name === name);

      console.log(
        `${name.padEnd(30)} : ${exists ? "EXISTS" : "AVAILABLE"}`
      );
    }

    console.log("\n===== TARGET TABLE COLUMNS IF PRESENT =====");

    const targetColumns = await client.query(`
      SELECT
        table_name,
        ordinal_position,
        column_name,
        data_type,
        udt_name,
        is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name IN (
          'companies',
          'users',
          'warehouses',
          'marketplace_accounts',
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
          'scan_transactions'
        )
      ORDER BY table_name, ordinal_position
    `);

    if (targetColumns.rows.length === 0) {
      console.log("No target-schema tables currently exist.");
    } else {
      console.table(targetColumns.rows);
    }

    console.log("\n===== LEGACY IDENTIFIER DATA =====");

    const identifiers = await client.query(`
      SELECT
        oi.identifier_type,
        COUNT(*)::int AS count
      FROM order_identifiers oi
      GROUP BY oi.identifier_type
      ORDER BY oi.identifier_type
    `);

    console.table(identifiers.rows);

    console.log("\n===== LEGACY IDENTIFIER SAMPLES =====");

    const identifierSamples = await client.query(`
      SELECT
        id,
        company_id,
        order_id,
        identifier_type,
        identifier_value,
        normalized_value,
        source
      FROM order_identifiers
      ORDER BY created_at, id
      LIMIT 50
    `);

    console.table(identifierSamples.rows);

    console.log("\n===== LEGACY RECORDING / EVIDENCE RELATION =====");

    const recordings = await client.query(`
      SELECT
        r.id AS recording_id,
        r."companyId",
        r."operatorId",
        r."stationId",
        r.status,
        r.mode,
        r."orderId",
        r."segmentCount",
        r."b2KeyPrefix",
        r."startedAt",
        r."stoppedAt",
        e.id AS evidence_id,
        e.status AS evidence_status,
        e."frameCount",
        e."orderId" AS evidence_order_id
      FROM "Recording" r
      LEFT JOIN "Evidence" e
        ON e."recordingId" = r.id
      ORDER BY r."createdAt", r.id
    `);

    console.table(recordings.rows);

    console.log("\n===== LEGACY USERS FOR IDENTITY MIGRATION =====");

    const users = await client.query(`
      SELECT
        u.id,
        u."clerkId",
        u."companyId",
        u."employeeId",
        u.name,
        u.email,
        u.role,
        u."warehouseId",
        u.status
      FROM "User" u
      ORDER BY u."createdAt", u.id
    `);

    console.table(users.rows);

    console.log("\n===== AUDIT COMPLETE =====");

  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("\n===== AUDIT FAILED =====");
  console.error(error);
  process.exit(1);
});
