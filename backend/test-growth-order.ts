import { billingService } from "./src/services/billing/billing.service.js";
import { prisma } from "./src/config/prisma.js";

const companyId = "839ed240-e938-49fb-ae9f-7462084ea7a1";

async function main() {
  console.log("===== GROWTH ORDER TEST =====");

  const result = await billingService.createPlanOrder({
    companyId,
    planCode: "growth",
    billingInterval: "MONTHLY",
  });

  console.log("===== ORDER RESULT =====");

  console.dir(
    {
      paymentId: result.payment.id,
      razorpay: result.razorpay,
      plan: result.plan,
    },
    { depth: null },
  );

  console.log("===== STORED BILLING PAYMENT =====");

  const rows = await prisma.$queryRawUnsafe<
    Array<{
      id: string;
      companyId: string;
      plan: string;
      billingInterval: string;
      amountPaise: bigint;
      gstPaise: bigint;
      totalPaise: bigint;
      status: string;
      providerOrderId: string | null;
      metadata: unknown;
    }>
  >(
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
      "metadata"
    FROM "BillingPayment"
    WHERE "id" = $1
    LIMIT 1
    `,
    result.payment.id,
  );

  const payment = rows[0];

  if (!payment) {
    throw new Error("BillingPayment was not found after order creation.");
  }

  console.table([
    {
      id: payment.id,
      plan: payment.plan,
      billingInterval: payment.billingInterval,
      subtotal: `₹${Number(payment.amountPaise) / 100}`,
      gst: `₹${Number(payment.gstPaise) / 100}`,
      total: `₹${Number(payment.totalPaise) / 100}`,
      status: payment.status,
      providerOrderId: payment.providerOrderId,
    },
  ]);

  console.log("===== METADATA =====");
  console.dir(payment.metadata, { depth: null });

  console.log("===== COMPANY PLAN CHECK =====");

  const companies = await prisma.$queryRawUnsafe<
    Array<{ plan: string }>
  >(
    `
    SELECT plan::text AS plan
    FROM "Company"
    WHERE id = $1
    `,
    companyId,
  );

  console.table(companies);
}

main()
  .catch((error) => {
    console.error("GROWTH ORDER TEST FAILED");
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
