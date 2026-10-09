-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "BillingInterval" AS ENUM ('MONTHLY', 'YEARLY');

-- CreateEnum
CREATE TYPE "SubscriptionProvider" AS ENUM ('MANUAL', 'RAZORPAY', 'STRIPE', 'OTHER');

-- CreateEnum
CREATE TYPE "ScanTransactionType" AS ENUM ('ALLOCATION', 'CONSUMPTION', 'TOPUP', 'REFUND', 'ADJUSTMENT', 'EXPIRATION');

-- CreateTable
CREATE TABLE "plans" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "monthlyPrice" DECIMAL(12,2),
    "yearlyPrice" DECIMAL(12,2),
    "monthlyScanCredits" INTEGER NOT NULL DEFAULT 0,
    "maxWarehouses" INTEGER NOT NULL DEFAULT 1,
    "maxOperators" INTEGER NOT NULL DEFAULT 1,
    "maxOrdersPerMonth" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'TRIALING',
    "billingInterval" "BillingInterval" NOT NULL DEFAULT 'MONTHLY',
    "provider" "SubscriptionProvider" NOT NULL DEFAULT 'MANUAL',
    "providerCustomerId" TEXT,
    "providerSubscriptionId" TEXT,
    "currentPeriodStart" TIMESTAMP(3),
    "currentPeriodEnd" TIMESTAMP(3),
    "trialEnd" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scan_wallets" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "balance" INTEGER NOT NULL DEFAULT 0,
    "lifetimeAllocated" INTEGER NOT NULL DEFAULT 0,
    "lifetimeConsumed" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "scan_wallets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scan_transactions" (
    "id" TEXT NOT NULL,
    "walletId" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "type" "ScanTransactionType" NOT NULL,
    "credits" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "referenceType" TEXT,
    "referenceId" TEXT,
    "idempotencyKey" TEXT,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scan_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "plans_code_key" ON "plans"("code");

-- CreateIndex
CREATE INDEX "plans_isActive_idx" ON "plans"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_companyId_key" ON "subscriptions"("companyId");

-- CreateIndex
CREATE INDEX "subscriptions_planId_idx" ON "subscriptions"("planId");

-- CreateIndex
CREATE INDEX "subscriptions_status_idx" ON "subscriptions"("status");

-- CreateIndex
CREATE INDEX "subscriptions_providerSubscriptionId_idx" ON "subscriptions"("providerSubscriptionId");

-- CreateIndex
CREATE UNIQUE INDEX "scan_wallets_companyId_key" ON "scan_wallets"("companyId");

-- CreateIndex
CREATE INDEX "scan_wallets_balance_idx" ON "scan_wallets"("balance");

-- CreateIndex
CREATE UNIQUE INDEX "scan_transactions_idempotencyKey_key" ON "scan_transactions"("idempotencyKey");

-- CreateIndex
CREATE INDEX "scan_transactions_walletId_createdAt_idx" ON "scan_transactions"("walletId", "createdAt");

-- CreateIndex
CREATE INDEX "scan_transactions_companyId_createdAt_idx" ON "scan_transactions"("companyId", "createdAt");

-- CreateIndex
CREATE INDEX "scan_transactions_type_idx" ON "scan_transactions"("type");

-- CreateIndex
CREATE INDEX "scan_transactions_referenceType_referenceId_idx" ON "scan_transactions"("referenceType", "referenceId");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_planId_fkey" FOREIGN KEY ("planId") REFERENCES "plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scan_wallets" ADD CONSTRAINT "scan_wallets_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scan_transactions" ADD CONSTRAINT "scan_transactions_walletId_fkey" FOREIGN KEY ("walletId") REFERENCES "scan_wallets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
