require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  // Rename column if old name still exists
  const col = await c.query(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'User'
      AND column_name IN ('clerkId', 'firebaseUid')
  `);
  console.log("columns now:", col.rows);

  const names = col.rows.map((r) => r.column_name);
  if (names.includes("clerkId") && !names.includes("firebaseUid")) {
    await c.query(`ALTER TABLE "User" RENAME COLUMN "clerkId" TO "firebaseUid"`);
    console.log("RENAMED clerkId → firebaseUid");
  } else if (names.includes("firebaseUid")) {
    console.log("Already firebaseUid — OK");
  } else {
    await c.query(`ALTER TABLE "User" ADD COLUMN "firebaseUid" TEXT`);
    console.log("ADDED firebaseUid column");
  }

  // Optional: unique index for lookups
  await c.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS "User_firebaseUid_key"
    ON "User" ("firebaseUid")
    WHERE "firebaseUid" IS NOT NULL
  `);

  const after = await c.query(`
    SELECT column_name FROM information_schema.columns
    WHERE table_name = 'User' AND column_name IN ('clerkId', 'firebaseUid')
  `);
  console.log("columns after:", after.rows);

  await c.end();
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
