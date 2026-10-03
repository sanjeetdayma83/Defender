import "dotenv/config";
import pg from "pg";

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

try {
  const labels = await pool.query(`
    SELECT t.typname, e.enumlabel
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname ILIKE '%market%'
    ORDER BY t.typname, e.enumsortorder
  `);
  console.log("ENUM LABELS:", JSON.stringify(labels.rows, null, 2));

  const col = await pool.query(`
    SELECT table_schema, column_name, data_type, udt_name
    FROM information_schema.columns
    WHERE table_name = 'Order' AND column_name = 'marketplace'
  `);
  console.log("ORDER.marketplace column:", JSON.stringify(col.rows, null, 2));

  const samples = await pool.query(`
    SELECT DISTINCT marketplace::text AS marketplace
    FROM "Order"
    LIMIT 20
  `);
  console.log("SAMPLES:", JSON.stringify(samples.rows, null, 2));
} catch (e) {
  console.error("ERR:", e?.message || e);
} finally {
  await pool.end();
}
