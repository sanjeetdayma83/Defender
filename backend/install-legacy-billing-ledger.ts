import { prisma } from "./src/config/prisma.js";

try {
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS "BillingPayment" (
      "id" TEXT PRIMARY KEY,
      "companyId" TEXT NOT NULL,
      "provider" TEXT NOT NULL DEFAULT 'RAZORPAY',
      "providerOrderId" TEXT UNIQUE,
      "providerPaymentId" TEXT UNIQUE,
      "status" TEXT NOT NULL DEFAULT 'PENDING',
      "plan" TEXT NOT NULL,
      "billingInterval" TEXT NOT NULL DEFAULT 'MONTHLY',
      "currency" TEXT NOT NULL DEFAULT 'INR',
      "amountPaise" BIGINT NOT NULL,
      "gstPaise" BIGINT NOT NULL DEFAULT 0,
      "totalPaise" BIGINT NOT NULL,
      "providerSignature" TEXT,
      "metadata" JSONB,
      "failureReason" TEXT,
      "paidAt" TIMESTAMP,
      "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      "updatedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS "BillingPayment_companyId_idx"
    ON "BillingPayment" ("companyId")
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS "BillingPayment_status_idx"
    ON "BillingPayment" ("status")
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS "BillingWebhookEvent" (
      "id" TEXT PRIMARY KEY,
      "provider" TEXT NOT NULL DEFAULT 'RAZORPAY',
      "eventId" TEXT NOT NULL,
      "eventType" TEXT NOT NULL,
      "payload" JSONB NOT NULL,
      "processed" BOOLEAN NOT NULL DEFAULT FALSE,
      "processedAt" TIMESTAMP,
      "failureReason" TEXT,
      "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      "updatedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "BillingWebhookEvent_provider_eventId_key"
        UNIQUE ("provider", "eventId")
    )
  `);

  console.log("BillingPayment table: READY");
  console.log("BillingWebhookEvent table: READY");
} finally {
  await prisma.$disconnect();
}
