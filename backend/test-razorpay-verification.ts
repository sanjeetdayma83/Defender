import "dotenv/config";

import { prisma } from "./src/config/prisma.js";
import { billingService } from "./src/services/billing/billing.service.js";

const companyId = "839ed240-e938-49fb-ae9f-7462084ea7a1";

const paymentId = "eeb3f358-0c4d-4b99-9685-b5e3559ad329";
const razorpayPaymentId = "pay_TiMYQXlfdWxLcH";
const razorpayOrderId = "order_TiMRs0j5opbuUz";
const razorpaySignature =
  "d89a734a387c43e0bb19dc1e8e620a3b36ad928ec3ebebd3c7c79f3c3663318c";

try {
  console.log("============================================");
  console.log(" RAZORPAY PAYMENT VERIFICATION TEST");
  console.log("============================================");

  const result = await billingService.verifyAndConfirmPayment({
    companyId,
    paymentId,
    razorpayPaymentId,
    razorpayOrderId,
    razorpaySignature,
  });

  console.log("");
  console.log("PAYMENT VERIFIED SUCCESSFULLY");
  console.log("--------------------------------------------");
  console.log("Payment ID        :", result.id);
  console.log("Provider          :", result.provider);
  console.log("Provider Payment  :", result.providerPaymentId);
  console.log("Provider Order    :", result.providerOrderId);
  console.log("Status            :", result.status);
  console.log("Plan              :", result.plan);
  console.log("Billing Interval  :", result.billingInterval);
  console.log("Amount (paise)    :", result.totalPaise.toString());
  console.log("Paid At           :", result.paidAt);
  console.log("--------------------------------------------");

  const company = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyName",
      plan::text AS plan,
      status::text AS status
    FROM "Company"
    WHERE id = $1
    LIMIT 1
    `,
    companyId,
  );

  console.log("");
  console.log("COMPANY AFTER PAYMENT");
  console.log("--------------------------------------------");
  console.log(company[0]);

  const subscription = await prisma.$queryRawUnsafe<any[]>(
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
    LIMIT 1
    `,
    companyId,
  );

  console.log("");
  console.log("BILLING SUBSCRIPTION");
  console.log("--------------------------------------------");
  console.log(subscription[0] ?? "NO EXISTING SUBSCRIPTION");

  console.log("");
  console.log("============================================");
  console.log(" FULL PAYMENT VERIFICATION TEST PASSED");
  console.log("============================================");
} catch (error) {
  console.error("");
  console.error("PAYMENT VERIFICATION FAILED");
  console.error("--------------------------------------------");
  console.error(error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
