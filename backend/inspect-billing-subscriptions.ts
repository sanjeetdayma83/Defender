import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.billingSubscription.findMany({
    select: {
      id: true,
      companyId: true,
      razorpaySubId: true,
      plan: true,
      status: true,
      currentPeriodStart: true,
      currentPeriodEnd: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  console.table(rows);
  console.log(`BillingSubscription rows: ${rows.length}`);
} finally {
  await prisma.$disconnect();
}
