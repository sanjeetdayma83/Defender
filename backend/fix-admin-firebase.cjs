require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const firebaseUid = "D0bFgcVHWoVYSQbqkpA5qv2P3tv2";
  const email = "support@lossdefender.in";

  let companyId;
  const cos = await c.query(
    `SELECT id FROM "Company" WHERE "companyName" = $1 LIMIT 1`,
    ["Loss Defender Platform"]
  );
  if (cos.rows.length) companyId = cos.rows[0].id;
  else {
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

  const found = await c.query(
    `SELECT id FROM "User" WHERE lower(email) = lower($1) OR "firebaseUid" = $2 LIMIT 1`,
    [email, firebaseUid]
  );

  if (found.rows.length) {
    const u = await c.query(
      `UPDATE "User" SET
         "firebaseUid" = $1,
         role = 'super_admin',
         status = 'active',
         "companyId" = $2,
         email = $3,
         name = COALESCE(name, 'Platform Admin'),
         "updatedAt" = NOW()
       WHERE id = $4
       RETURNING id, email, role, "firebaseUid", status`,
      [firebaseUid, companyId, email, found.rows[0].id]
    );
    console.log("UPDATED", u.rows[0]);
  } else {
    const u = await c.query(
      `INSERT INTO "User" (
         id, "firebaseUid", email, name, role, status, "companyId", "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text, $1, $2, 'Platform Admin', 'super_admin', 'active', $3, NOW(), NOW()
       )
       RETURNING id, email, role, "firebaseUid", status`,
      [firebaseUid, email, companyId]
    );
    console.log("CREATED", u.rows[0]);
  }

  await c.end();
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
