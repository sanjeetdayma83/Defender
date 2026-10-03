require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const tables = await c.query(`
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND table_type = 'BASE TABLE'
      AND (
        table_name ILIKE '%user%'
        OR table_name ILIKE '%compan%'
        OR table_name ILIKE '%warehouse%'
      )
    ORDER BY 1, 2
  `);
  console.log("TABLES:", JSON.stringify(tables.rows, null, 2));

  try {
    const u = await c.query(`
      SELECT id, email, role, "firebaseUid", "isActive", "companyId"
      FROM users
      LIMIT 5
    `);
    console.log("users sample:", u.rows);
  } catch (e) {
    console.log("users query error:", e.message);
  }

  try {
    const u2 = await c.query(`
      SELECT id, email, role, "clerkId", status, "companyId"
      FROM "User"
      LIMIT 5
    `);
    console.log("User sample:", u2.rows);
  } catch (e) {
    console.log("User query error:", e.message);
  }

  try {
    const co = await c.query(`
      SELECT id, name, code, "isActive" FROM companies LIMIT 5
    `);
    console.log("companies sample:", co.rows);
  } catch (e) {
    console.log("companies query error:", e.message);
  }

  try {
    const co2 = await c.query(`
      SELECT id, "companyName", status FROM "Company" LIMIT 5
    `);
    console.log("Company sample:", co2.rows);
  } catch (e) {
    console.log("Company query error:", e.message);
  }

  await c.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
