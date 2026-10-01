import crypto from "node:crypto";
import { prisma } from "./src/config/prisma.js";
import { BillingService } from "./src/services/billing/billing.service.js";

const COMPANY_ID = "af91a0db-c225-4d61-bc6c-55659eb9edc9";

async function main() {
  const billingService = new BillingService();

  const paymentId = crypto.randomUUID();
  const orderId = `test_order_${crypto.randomUUID().replaceAll("-", "")}`;

  console.log("========================================");
  console.log(" BILLING → SCAN ALLOCATION TEST");
  console.log("========================================");

  console.log("\n[1] Creating temporary Growth BillingPayment...");

  await prisma.$executeRawUnsafe(
    `
    INSERT INTO "BillingPayment" (
      "id",
      "companyId",
      "provider",
      "providerOrderId",
      "providerPaymentId",
      "status",
      "plan",
      "billingInterval",
      "currency",
      "amountPaise",
      "gstPaise",
      "totalPaise",
      "metadata",
      "createdAt",
      "updatedAt"
    )
    VALUES (
      $1,
      $2,
      'RAZORPAY',
      $3,
      NULL,
      'PENDING',
      'growth',
      'MONTHLY',
      'INR',
      2000000,
      360000,
      2360000,
      $4::jsonb,
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    )
    `,
    paymentId,
    COMPANY_ID,
    orderId,
    JSON.stringify({
      planCode: "growth",
      billingInterval: "MONTHLY",
      gstPercent: 18,
      validityMonths: 6,
      includedScans: 22200,
      maxWarehouses: 3,
      maxOperators: 10,
      retentionDays: 30,
      commercialPlan: true,
      testPayment: true,
    }),
  );

  console.log("Payment ID:", paymentId);
  console.log("Order ID:", orderId);

  console.log("\n[2] Confirming temporary payment...");

  const confirmed = await billingService.confirmRazorpayPayment({
    paymentId,
    razorpayPaymentId: "test_payment_scan_allocation_001",
    razorpaySignature: "test_signature",
  });

  console.log("Payment confirmation result:");
  console.table({
    id: confirmed.id,
    companyId: confirmed.companyId,
    status: confirmed.status,
    plan: confirmed.plan,
    providerPaymentId: confirmed.providerPaymentId,
  });

  console.log("\n[3] Checking Company...");

  const company = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyName",
      plan::text AS plan,
      status::text AS status
    FROM "Company"
    WHERE id = $1
    `,
    COMPANY_ID,
  );

  console.table(company);

  console.log("\n[4] Checking BillingSubscription...");

  const subscriptions = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyId",
      "razorpaySubId",
      plan::text AS plan,
      status,
      "currentPeriodStart",
      "currentPeriodEnd"
    FROM "BillingSubscription"
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  console.table(subscriptions);

  console.log("\n[5] Checking ScanWallet...");

  const wallets = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyId",
      balance,
      "lifetimeAllocated",
      "lifetimeConsumed"
    FROM scan_wallets
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  console.table(wallets);

  console.log("\n[6] Checking scan transaction...");

  const transactions = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      type,
      credits,
      "balanceAfter",
      "referenceType",
      "referenceId",
      "idempotencyKey"
    FROM scan_transactions
    WHERE "companyId" = $1
    ORDER BY "createdAt" DESC
    `,
    COMPANY_ID,
  );

  console.table(transactions);

  console.log("\n[7] Re-running confirmation to test idempotency...");

  const confirmedAgain = await billingService.confirmRazorpayPayment({
    paymentId,
    razorpayPaymentId: "test_payment_scan_allocation_001",
    razorpaySignature: "test_signature",
  });

  console.log("Second confirmation returned:");
  console.table({
    id: confirmedAgain.id,
    status: confirmedAgain.status,
    plan: confirmedAgain.plan,
  });

  const walletAfterRetry = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      balance,
      "lifetimeAllocated",
      "lifetimeConsumed"
    FROM scan_wallets
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  const allocationCountAfterRetry = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      COUNT(*)::int AS count
    FROM scan_transactions
    WHERE
      "companyId" = $1
      AND "referenceType" = 'BILLING_PAYMENT'
      AND "referenceId" = $2
    `,
    COMPANY_ID,
    paymentId,
  );

  console.log("\nWallet after retry:");
  console.table(walletAfterRetry);

  console.log("\nBilling allocation count after retry:");
  console.table(allocationCountAfterRetry);

  console.log("\n[8] Cleaning up temporary billing test...");

  await prisma.$executeRawUnsafe(
    `
    DELETE FROM scan_transactions
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  await prisma.$executeRawUnsafe(
    `
    DELETE FROM scan_wallets
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  await prisma.$executeRawUnsafe(
    `
    DELETE FROM "BillingSubscription"
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  await prisma.$executeRawUnsafe(
    `
    DELETE FROM "BillingPayment"
    WHERE "id" = $1
    `,
    paymentId,
  );

  await prisma.$executeRawUnsafe(
    `
    UPDATE "Company"
    SET
      "plan" = 'free'::"Plan",
      "updatedAt" = CURRENT_TIMESTAMP
    WHERE "id" = $1
    `,
    COMPANY_ID,
  );

  console.log("Cleanup complete.");

  console.log("\n========================================");
  console.log(" BILLING → SCAN TEST COMPLETE");
  console.log("========================================");
}

main()
  .catch((error) => {
    console.error("\nBILLING → SCAN TEST FAILED");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
