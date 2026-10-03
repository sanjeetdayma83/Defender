require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const firebaseUid = "D0bFgcVHWoVYSQbqkpA5qv2P3tv2";
  const email = "support@lossdefender.in";

  // 1) Column name
  const cols = await c.query(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'User'
      AND column_name IN ('clerkId', 'firebaseUid')
  `);
  const names = cols.rows.map((r) => r.column_name);
  console.log("UID columns:", names);

  if (names.includes("clerkId") && !names.includes("firebaseUid")) {
    await c.query(`ALTER TABLE "User" RENAME COLUMN "clerkId" TO "firebaseUid"`);
    console.log("RENAMED clerkId → firebaseUid");
  } else if (!names.includes("firebaseUid") && !names.includes("clerkId")) {
    await c.query(`ALTER TABLE "User" ADD COLUMN "firebaseUid" TEXT`);
    console.log("ADDED firebaseUid");
  }

  // 2) Company
  let companyId;
  const cos = await c.query(
    `SELECT id FROM "Company" WHERE "companyName" = $1 LIMIT 1`,
    ["Loss Defender Platform"]
  );
  if (cos.rows.length) {
    companyId = cos.rows[0].id;
  } else {
    const ins = await c.query(
      `INSERT INTO "Company" (
         id, "companyName", email, status, timezone, currency, "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text, $1, $2, 'active', 'Asia/Kolkata', 'INR', NOW(), NOW()
       ) RETURNING id`,
      ["Loss Defender Platform", email]
    );
    companyId = ins.rows[0].id;
  }
  console.log("companyId:", companyId);

  // 3) Find any matching user
  const found = await c.query(
    `SELECT id, email, role, status, "firebaseUid", "companyId"
     FROM "User"
     WHERE "firebaseUid" = $1 OR lower(email) = lower($2)`,
    [firebaseUid, email]
  );
  console.log("found before:", found.rows);

  if (found.rows.length) {
    const u = await c.query(
      `UPDATE "User" SET
         "firebaseUid" = $1,
         role = 'super_admin',
         status = 'active',
         "companyId" = $2,
         email = $3,
         name = COALESCE(NULLIF(name, ''), 'Platform Admin'),
         "updatedAt" = NOW()
       WHERE id = $4
       RETURNING id, email, role, status, "firebaseUid", "companyId"`,
      [firebaseUid, companyId, email, found.rows[0].id]
    );
    console.log("UPDATED:", u.rows[0]);
  } else {
    const u = await c.query(
      `INSERT INTO "User" (
         id, "firebaseUid", email, name, role, status, "companyId", "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text, $1, $2, 'Platform Admin', 'super_admin', 'active', $3, NOW(), NOW()
       )
       RETURNING id, email, role, status, "firebaseUid", "companyId"`,
      [firebaseUid, email, companyId]
    );
    console.log("CREATED:", u.rows[0]);
  }

  // 4) Exact lookup identity service will use
  const check = await c.query(
    `SELECT id, email, role, status, "firebaseUid"
     FROM "User" WHERE "firebaseUid" = $1`,
    [firebaseUid]
  );
  console.log("LOOKUP BY firebaseUid:", check.rows);

  await c.end();
}

main().catch((e) => {
  console.error("FAIL:", e.message);
  if (e.detail) console.error("detail:", e.detail);
  process.exit(1);
});
