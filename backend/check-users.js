require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const tables = await c.query(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name IN ('users', 'User', 'companies', 'Company')
  `);
  console.log("tables:", tables.rows);

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

  await c.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
