require("dotenv").config();
const { Client } = require("pg");

async function main() {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const firebaseUid = "D0bFgcVHWoVYSQbqkpA5qv2P3tv2";
  const email = "support@lossdefender.in";

  let companyId;
  const cos = await c.query(
    `SELECT id FROM "Company" WHERE "companyName" = $1 OR email = $2 LIMIT 1`,
    ["Loss Defender Platform", email]
  );

  if (cos.rows.length) {
    companyId = cos.rows[0].id;
    console.log("company exists", companyId);
  } else {
    const ins = await c.query(
      `INSERT INTO "Company" (
         id, "companyName", email, phone, status, timezone, currency,
         "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text,
         $1, $2, $3,
         'active', 'Asia/Kolkata', 'INR',
         NOW(), NOW()
       ) RETURNING id`,
      ["Loss Defender Platform", email, "0000000000"]
    );
    companyId = ins.rows[0].id;
    console.log("company created", companyId);
  }

  const found = await c.query(
    `SELECT id FROM "User"
     WHERE "firebaseUid" = $1 OR lower(email) = lower($2)
     LIMIT 1`,
    [firebaseUid, email]
  );

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
       RETURNING id, email, role::text, status::text, "firebaseUid"`,
      [firebaseUid, companyId, email, found.rows[0].id]
    );
    console.log("UPDATED USER", u.rows[0]);
  } else {
    const u = await c.query(
      `INSERT INTO "User" (
         id, "firebaseUid", email, name, role, status, "companyId",
         "createdAt", "updatedAt"
       ) VALUES (
         gen_random_uuid()::text, $1, $2, 'Platform Admin',
         'super_admin', 'active', $3, NOW(), NOW()
       )
       RETURNING id, email, role::text, status::text, "firebaseUid"`,
      [firebaseUid, email, companyId]
    );
    console.log("CREATED USER", u.rows[0]);
  }

  const check = await c.query(
    `SELECT id, email, role::text, status::text, "firebaseUid"
     FROM "User" WHERE "firebaseUid" = $1`,
    [firebaseUid]
  );
  console.log("LOOKUP", check.rows);

  await c.end();
}

main().catch((e) => {
  console.error("FAIL:", e.message);
  if (e.detail) console.error(e.detail);
  process.exit(1);
});
