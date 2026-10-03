require("dotenv").config();
const { Client } = require("pg");
(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const r = await c.query(`
    SELECT column_name, data_type, udt_name
    FROM information_schema.columns
    WHERE table_name = 'User' AND column_name = 'role'
  `);
  console.log(r.rows);
  try {
    const e = await c.query(`
      SELECT enumlabel FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      WHERE t.typname ILIKE '%role%'
      ORDER BY enumsortorder
    `);
    console.log("enums:", e.rows);
  } catch (err) { console.log(err.message); }
  await c.end();
})().catch(console.error);
