import "dotenv/config";
import pg from "pg";

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
try {
  const r = await pool.query(`
    SELECT id, awb, "marketplaceOrderId", marketplace::text AS marketplace,
           status::text AS status, "companyId", "createdAt"
    FROM "Order"
    ORDER BY "createdAt" DESC
    LIMIT 15
  `);
  console.log(JSON.stringify(r.rows, null, 2));
} catch (e) {
  console.error("ERR:", e.message);
} finally {
  await pool.end();
}
