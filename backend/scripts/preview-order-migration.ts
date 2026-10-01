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
    console.log("\n===== LEGACY ORDER MIGRATION PREVIEW =====");

    const result = await client.query(`
      SELECT
        o.id AS legacy_order_id,
        o."companyId",
        o."warehouseId",
        o.marketplace,
        o."marketplaceOrderId",
        o.status,
        o.awb,
        o.courier,
        jsonb_array_length(o.items) AS item_count,
        o.items
      FROM "Order" o
      ORDER BY o."createdAt", o.id
    `);

    for (const row of result.rows) {
      console.log("\n----------------------------------------");

      console.log("Legacy Order ID :", row.legacy_order_id);
      console.log("Company ID      :", row.companyId);
      console.log("Warehouse ID    :", row.warehouseId);
      console.log("Marketplace     :", row.marketplace);
      console.log("Marketplace ID  :", row.marketplaceOrderId);
      console.log("Status          :", row.status);
      console.log("AWB             :", row.awb);
      console.log("Courier         :", row.courier);
      console.log("Item Count      :", row.item_count);

      console.log("Items:");
      console.dir(row.items, { depth: null });
    }

    console.log("\n===== DUPLICATE MARKETPLACE ORDER IDS =====");

    const duplicates = await client.query(`
      SELECT
        "companyId",
        marketplace,
        "marketplaceOrderId",
        COUNT(*)::int AS count,
        array_agg(id ORDER BY id) AS legacy_order_ids
      FROM "Order"
      WHERE "marketplaceOrderId" IS NOT NULL
      GROUP BY
        "companyId",
        marketplace,
        "marketplaceOrderId"
      HAVING COUNT(*) > 1
      ORDER BY count DESC
    `);

    console.table(duplicates.rows);

    console.log("\n===== AWB DUPLICATES =====");

    const awbDuplicates = await client.query(`
      SELECT
        awb,
        COUNT(*)::int AS count,
        array_agg(id ORDER BY id) AS legacy_order_ids
      FROM "Order"
      WHERE awb IS NOT NULL
        AND trim(awb) <> ''
      GROUP BY awb
      HAVING COUNT(*) > 1
      ORDER BY count DESC
    `);

    console.table(awbDuplicates.rows);

    console.log("\n===== ORDERS WITHOUT WAREHOUSE =====");

    const noWarehouse = await client.query(`
      SELECT
        id,
        "companyId",
        "marketplaceOrderId",
        marketplace
      FROM "Order"
      WHERE "warehouseId" IS NULL
      ORDER BY id
    `);

    console.table(noWarehouse.rows);

  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("\n===== MIGRATION PREVIEW FAILED =====");
  console.error(error);
  process.exit(1);
});
