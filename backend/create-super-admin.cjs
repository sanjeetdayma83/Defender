require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const firebaseUid = "D0bFgcVHWoVYSQbqkpA5qv2P3tv2";
  const email = "support@lossdefender.in";

  // Company columns vary — insert with required email
  let companyId;
  const existing = await c.query(
    `SELECT id FROM "Company" WHERE "companyName" = $1 LIMIT 1`,
    ["Loss Defender Platform"]
  );

  if (existing.rows.length) {
    companyId = existing.rows[0].id;
    console.log("company exists", companyId);
  } else {
    const ins = await c.query(
      `INSERT INTO "Company" (
         id, "companyName", email, status, timezone, currency,
         "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text,
         $1,
         $2,
         'active',
         'Asia/Kolkata',
         'INR',
         NOW(),
         NOW()
       )
       RETURNING id`,
      ["Loss Defender Platform", email]
    );
    companyId = ins.rows[0].id;
    console.log("company created", companyId);
  }

  const byEmail = await c.query(
    `SELECT id FROM "User" WHERE lower(email) = lower($1) LIMIT 1`,
    [email]
  );

  if (byEmail.rows.length) {
    const u = await c.query(
      `UPDATE "User"
       SET "clerkId" = $1,
           role = 'super_admin',
           status = 'active',
           "companyId" = $2,
           name = COALESCE(name, 'Platform Admin'),
           "updatedAt" = NOW()
       WHERE id = $3
       RETURNING id, email, role, "clerkId", status, "companyId"`,
      [firebaseUid, companyId, byEmail.rows[0].id]
    );
    console.log("updated user", u.rows[0]);
  } else {
    const u = await c.query(
      `INSERT INTO "User" (
         id, "clerkId", email, name, role, status, "companyId", "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text, $1, $2, $3, 'super_admin', 'active', $4, NOW(), NOW()
       )
       RETURNING id, email, role, "clerkId", status, "companyId"`,
      [firebaseUid, email, "Platform Admin", companyId]
    );
    console.log("created user", u.rows[0]);
  }

  await c.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
