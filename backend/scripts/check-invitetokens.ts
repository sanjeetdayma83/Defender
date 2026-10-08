import { prisma } from "../src/config/prisma.ts";

async function main() {
  console.log("===== INVITETOKEN DATABASE CHECK =====");

  const rows = await prisma.$queryRawUnsafe(`
    SELECT
      id,
      "userId",
      LEFT("tokenHash", 16) AS "hashPrefix",
      LENGTH("tokenHash") AS "hashLength",
      "expiresAt",
      "usedAt",
      "createdAt"
    FROM "InviteToken"
    ORDER BY "createdAt" DESC
  `);

  console.table(rows);
  console.log("");
  console.log("Rows:", rows.length);
  console.log("No database changes were made.");
  console.log("===== CHECK COMPLETE =====");
}

main()
  .catch((error) => {
    console.error("INVITETOKEN CHECK FAILED");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
