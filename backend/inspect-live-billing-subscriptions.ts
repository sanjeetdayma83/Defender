import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.$queryRawUnsafe(`
    SELECT
      id,
      "companyId",
      "razorpaySubId",
      plan,
      status,
      "currentPeriodStart",
      "currentPeriodEnd",
      "createdAt",
      "updatedAt"
    FROM "BillingSubscription"
    ORDER BY "createdAt" DESC
  `);

  console.table(rows);
  console.log(`BillingSubscription rows: ${rows.length}`);
} finally {
  await prisma.$disconnect();
}
