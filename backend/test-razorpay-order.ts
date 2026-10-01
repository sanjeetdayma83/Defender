import "dotenv/config";

import { prisma } from "./src/config/prisma.js";
import { billingService } from "./src/services/billing/billing.service.js";

const companyId = "839ed240-e938-49fb-ae9f-7462084ea7a1";

try {
  console.log("============================================");
  console.log(" RAZORPAY TEST MODE - ORDER CREATION TEST");
  console.log("============================================");

  console.log("");
  console.log("Razorpay configured:", Boolean(
    process.env.RAZORPAY_KEY_ID &&
    process.env.RAZORPAY_KEY_SECRET
  ));

  console.log(
    "Starter monthly price:",
    process.env.RAZORPAY_STARTER_MONTHLY_PRICE_PAISE,
    "paise"
  );

  const result = await billingService.createPlanOrder({
    companyId,
    planCode: "starter",
    billingInterval: "MONTHLY",
  });

  console.log("");
  console.log("ORDER CREATED SUCCESSFULLY");
  console.log("--------------------------------------------");
  console.log("Internal Payment ID :", result.payment?.id);
  console.log("Razorpay Order ID   :", result.razorpay.orderId);
  console.log("Amount (paise)      :", result.razorpay.amount);
  console.log("Currency            :", result.razorpay.currency);
  console.log("Plan                :", result.plan.code);
  console.log("Billing Interval    :", result.plan.billingInterval);
  console.log("Subtotal (paise)    :", result.plan.subtotalPaise);
  console.log("GST (paise)         :", result.plan.gstPaise);
  console.log("Total (paise)       :", result.plan.totalPaise);
  console.log("--------------------------------------------");

  console.log("");
  console.log("SUCCESS: Razorpay Test Mode order created.");
} catch (error) {
  console.error("");
  console.error("TEST FAILED");
  console.error("--------------------------------------------");
  console.error(error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
