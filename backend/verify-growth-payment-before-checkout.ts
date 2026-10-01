import { prisma } from "./src/config/prisma.js";

async function main() {
  const paymentId = "e854de2d-bc85-4348-b9b2-c38031a88e29";

  const rows = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      "id",
      "companyId",
      "plan",
      "billingInterval",
      "amountPaise",
      "gstPaise",
      "totalPaise",
      "status",
      "providerOrderId",
      "providerPaymentId"
    FROM "BillingPayment"
    WHERE "id" = $1
    LIMIT 1
    `,
    paymentId,
  );

  console.dir(rows, { depth: null });

  const subscriptions = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      "id",
      "companyId",
      "razorpaySubId",
      plan::text AS plan,
      status,
      "currentPeriodStart",
      "currentPeriodEnd"
    FROM "BillingSubscription"
    ORDER BY "createdAt" DESC
    `,
  );

  console.log("===== SUBSCRIPTIONS =====");
  console.dir(subscriptions, { depth: null });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
