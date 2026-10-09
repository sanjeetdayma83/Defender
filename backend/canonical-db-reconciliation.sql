-- CreateEnum
CREATE TYPE "ClaimStatus" AS ENUM ('open', 'under_review', 'investigating', 'approved', 'rejected', 'escalated', 'closed');

-- CreateEnum
CREATE TYPE "IdentifierType" AS ENUM ('order_id', 'shipment_id', 'order_item_id', 'tracking_id', 'awb', 'barcode', 'qr', 'sku', 'fsn', 'invoice_no', 'other');

-- CreateEnum
CREATE TYPE "Plan" AS ENUM ('free', 'starter', 'professional', 'enterprise', 'growth');

-- CreateEnum
CREATE TYPE "RecordingMode" AS ENUM ('forward', 'return');

-- CreateEnum
CREATE TYPE "RecordingStatus" AS ENUM ('started', 'paused', 'completed', 'failed');

-- CreateEnum
CREATE TYPE "StationStatus" AS ENUM ('online', 'offline', 'maintenance', 'inactive');

-- CreateEnum
CREATE TYPE "Status" AS ENUM ('active', 'suspended', 'deleted');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('pending', 'active', 'suspended', 'deleted');

-- CreateEnum
CREATE TYPE "StorageObjectType" AS ENUM ('RECORDING', 'EVIDENCE', 'INVOICE', 'DOCUMENT', 'IMAGE', 'VIDEO', 'OTHER');

-- CreateEnum
CREATE TYPE "StorageUsageEventType" AS ENUM ('UPLOAD', 'DELETE', 'RESTORE', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('CREATED', 'PENDING', 'SUCCESS', 'FAILED', 'REFUNDED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PaymentItemType" AS ENUM ('PLAN', 'EXTRA_SCAN_PACK', 'RETENTION', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "SubscriptionEntitlementUnit" AS ENUM ('COUNT', 'DAYS', 'BOOLEAN');

-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('DRAFT', 'ISSUED', 'PAID', 'VOID', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "InvoiceItemType" AS ENUM ('PLAN', 'EXTRA_SCAN_PACK', 'RETENTION', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "AuditAction" AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'IMPORT', 'SCAN', 'PACKING_STARTED', 'EVIDENCE_UPLOADED', 'WALLET_CONSUMED', 'PACKING_COMPLETED', 'ORDER_PACKED', 'ERROR', 'PLAN_CREATED', 'PLAN_UPDATED', 'PLAN_DEACTIVATED', 'SUBSCRIPTION_CREATED', 'SUBSCRIPTION_ACTIVATED', 'SUBSCRIPTION_UPDATED', 'SUBSCRIPTION_CANCELLED', 'SUBSCRIPTION_EXPIRED', 'PAYMENT_CREATED', 'PAYMENT_SUCCESS', 'PAYMENT_FAILED', 'PAYMENT_REFUNDED', 'CREDIT_ALLOCATION', 'EXTRA_SCAN_PURCHASE', 'RETENTION_PURCHASE');

-- AlterEnum
BEGIN;
CREATE TYPE "EvidenceStatus_new" AS ENUM ('processing', 'ready', 'failed');
ALTER TABLE "public"."evidence_media" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Evidence" ALTER COLUMN "status" TYPE "EvidenceStatus_new" USING ("status"::text::"EvidenceStatus_new");
ALTER TABLE "evidence_media" ALTER COLUMN "status" TYPE "EvidenceStatus_new" USING ("status"::text::"EvidenceStatus_new");
ALTER TYPE "EvidenceStatus" RENAME TO "EvidenceStatus_old";
ALTER TYPE "EvidenceStatus_new" RENAME TO "EvidenceStatus";
DROP TYPE "public"."EvidenceStatus_old";
ALTER TABLE "evidence_media" ALTER COLUMN "status" SET DEFAULT 'processing';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "Marketplace_new" AS ENUM ('amazon', 'flipkart', 'meesho', 'shopify', 'woocommerce', 'manual');
ALTER TABLE "Claim" ALTER COLUMN "marketplace" TYPE "Marketplace_new" USING ("marketplace"::text::"Marketplace_new");
ALTER TABLE "MarketplaceAccount" ALTER COLUMN "marketplace" TYPE "Marketplace_new" USING ("marketplace"::text::"Marketplace_new");
ALTER TABLE "Order" ALTER COLUMN "marketplace" TYPE "Marketplace_new" USING ("marketplace"::text::"Marketplace_new");
ALTER TYPE "Marketplace" RENAME TO "Marketplace_old";
ALTER TYPE "Marketplace_new" RENAME TO "Marketplace";
DROP TYPE "public"."Marketplace_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "OrderStatus_new" AS ENUM ('synced', 'queued', 'packing', 'recording', 'scanned', 'evidence_ready', 'dispatched', 'shipped', 'claimed', 'returned', 'closed');
ALTER TABLE "public"."orders" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Order" ALTER COLUMN "status" TYPE "OrderStatus_new" USING ("status"::text::"OrderStatus_new");
ALTER TYPE "OrderStatus" RENAME TO "OrderStatus_old";
ALTER TYPE "OrderStatus_new" RENAME TO "OrderStatus";
DROP TYPE "public"."OrderStatus_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "UserRole_new" AS ENUM ('super_admin', 'company_admin', 'warehouse_manager', 'supervisor', 'packing_operator', 'qc_operator', 'claims_executive', 'marketplace_manager', 'viewer', 'auditor');
ALTER TABLE "public"."users" ALTER COLUMN "role" DROP DEFAULT;
ALTER TABLE "User" ALTER COLUMN "role" TYPE "UserRole_new" USING ("role"::text::"UserRole_new");
ALTER TYPE "UserRole" RENAME TO "UserRole_old";
ALTER TYPE "UserRole_new" RENAME TO "UserRole";
DROP TYPE "public"."UserRole_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "marketplace_accounts" DROP CONSTRAINT "marketplace_accounts_companyId_fkey";

-- DropForeignKey
ALTER TABLE "order_items" DROP CONSTRAINT "order_items_orderId_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_companyId_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_marketplaceAccountId_fkey";

-- DropForeignKey
ALTER TABLE "orders" DROP CONSTRAINT "orders_warehouseId_fkey";

-- DropForeignKey
ALTER TABLE "packing_sessions" DROP CONSTRAINT "packing_sessions_orderId_fkey";

-- DropForeignKey
ALTER TABLE "packing_sessions" DROP CONSTRAINT "packing_sessions_userId_fkey";

-- DropForeignKey
ALTER TABLE "packing_sessions" DROP CONSTRAINT "packing_sessions_warehouseId_fkey";

-- DropForeignKey
ALTER TABLE "products" DROP CONSTRAINT "products_companyId_fkey";

-- DropForeignKey
ALTER TABLE "scan_transactions" DROP CONSTRAINT "scan_transactions_walletId_fkey";

-- DropForeignKey
ALTER TABLE "scan_wallets" DROP CONSTRAINT "scan_wallets_companyId_fkey";

-- DropForeignKey
ALTER TABLE "shipments" DROP CONSTRAINT "shipments_orderId_fkey";

-- DropForeignKey
ALTER TABLE "subscriptions" DROP CONSTRAINT "subscriptions_companyId_fkey";

-- DropForeignKey
ALTER TABLE "subscriptions" DROP CONSTRAINT "subscriptions_planId_fkey";

-- DropForeignKey
ALTER TABLE "users" DROP CONSTRAINT "users_companyId_fkey";

-- DropForeignKey
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_companyId_fkey";

-- DropIndex
DROP INDEX "scan_transactions_companyId_createdAt_idx";

-- DropIndex
DROP INDEX "scan_transactions_idempotencyKey_key";

-- DropIndex
DROP INDEX "scan_transactions_walletId_createdAt_idx";

-- DropIndex
DROP INDEX "scan_wallets_balance_idx";

-- AlterTable
ALTER TABLE "evidence_media" ALTER COLUMN "status" SET DEFAULT 'processing';

-- AlterTable
ALTER TABLE "scan_transactions" DROP COLUMN "type",
ADD COLUMN     "type" TEXT NOT NULL,
ALTER COLUMN "createdAt" SET DATA TYPE TIMESTAMP(6);

-- AlterTable
ALTER TABLE "scan_wallets" ALTER COLUMN "createdAt" SET DATA TYPE TIMESTAMP(6),
ALTER COLUMN "updatedAt" SET DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "updatedAt" SET DATA TYPE TIMESTAMP(6);

-- DropTable
DROP TABLE "companies";

-- DropTable
DROP TABLE "marketplace_accounts";

-- DropTable
DROP TABLE "orders";

-- DropTable
DROP TABLE "plans";

-- DropTable
DROP TABLE "subscriptions";

-- DropTable
DROP TABLE "users";

-- DropTable
DROP TABLE "warehouses";

-- DropEnum
DROP TYPE "ScanTransactionType";

-- CreateTable
CREATE TABLE "invoices" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "billingPaymentId" TEXT,
    "invoiceNumber" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'DRAFT',
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "customerLegalName" TEXT NOT NULL,
    "customerDisplayName" TEXT,
    "customerGstin" TEXT,
    "customerPan" TEXT,
    "customerAddressLine1" TEXT,
    "customerAddressLine2" TEXT,
    "customerCity" TEXT,
    "customerState" TEXT,
    "customerStateCode" TEXT,
    "customerPostalCode" TEXT,
    "customerCountry" TEXT NOT NULL DEFAULT 'India',
    "customerBillingEmail" TEXT,
    "customerBillingPhone" TEXT,
    "placeOfSupplyState" TEXT,
    "placeOfSupplyStateCode" TEXT,
    "subtotalPaise" BIGINT NOT NULL,
    "gstPaise" BIGINT NOT NULL DEFAULT 0,
    "totalPaise" BIGINT NOT NULL,
    "issuedAt" TIMESTAMP(3),
    "paidAt" TIMESTAMP(3),
    "voidedAt" TIMESTAMP(3),
    "pdfStorageKey" TEXT,
    "pdfChecksum" TEXT,
    "pdfSizeBytes" BIGINT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoice_sequences" (
    "id" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "nextValue" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_sequences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoice_items" (
    "id" TEXT NOT NULL,
    "invoiceId" TEXT NOT NULL,
    "itemType" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "unitPricePaise" BIGINT NOT NULL,
    "taxableAmountPaise" BIGINT NOT NULL,
    "gstPercent" INTEGER NOT NULL DEFAULT 18,
    "gstPaise" BIGINT NOT NULL DEFAULT 0,
    "totalPaise" BIGINT NOT NULL,
    "referenceType" TEXT,
    "referenceId" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "beforeState" JSONB,
    "afterState" JSONB,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BillingPayment" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "provider" TEXT NOT NULL DEFAULT 'RAZORPAY',
    "providerOrderId" TEXT,
    "providerPaymentId" TEXT,
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
    "paidAt" TIMESTAMP(6),
    "createdAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BillingPayment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BillingSubscription" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "razorpaySubId" TEXT,
    "plan" "Plan" NOT NULL,
    "status" TEXT NOT NULL,
    "currentPeriodStart" TIMESTAMP(3) NOT NULL,
    "currentPeriodEnd" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BillingSubscription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BillingWebhookEvent" (
    "id" TEXT NOT NULL,
    "provider" TEXT NOT NULL DEFAULT 'RAZORPAY',
    "eventId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "processed" BOOLEAN NOT NULL DEFAULT false,
    "processedAt" TIMESTAMP(6),
    "failureReason" TEXT,
    "createdAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BillingWebhookEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Claim" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "marketplace" "Marketplace" NOT NULL,
    "description" TEXT,
    "status" "ClaimStatus" NOT NULL DEFAULT 'open',
    "decision" TEXT,
    "decidedBy" TEXT,
    "decidedAt" TIMESTAMP(3),
    "attachments" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Claim_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Company" (
    "id" TEXT NOT NULL,
    "companyName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "gst" TEXT,
    "pan" TEXT,
    "address" JSONB,
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "plan" "Plan" NOT NULL DEFAULT 'free',
    "storageUsed" BIGINT NOT NULL DEFAULT 0,
    "storageQuota" BIGINT NOT NULL DEFAULT 5368709120,
    "status" "Status" NOT NULL DEFAULT 'active',
    "logo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Company_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Evidence" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "recordingId" TEXT NOT NULL,
    "status" "EvidenceStatus" NOT NULL DEFAULT 'processing',
    "frameCount" INTEGER NOT NULL DEFAULT 0,
    "frames" JSONB,
    "checksum" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "orderId" TEXT,

    CONSTRAINT "Evidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InviteToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "usedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InviteToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MarketplaceAccount" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "marketplace" "Marketplace" NOT NULL,
    "accessToken" TEXT NOT NULL,
    "refreshToken" TEXT,
    "webhookSecret" TEXT,
    "status" "Status" NOT NULL DEFAULT 'active',
    "lastSyncAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MarketplaceAccount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "userId" TEXT,
    "channel" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "sentAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Order" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "warehouseId" TEXT,
    "marketplace" "Marketplace" NOT NULL DEFAULT 'manual',
    "marketplaceOrderId" TEXT,
    "status" "OrderStatus" NOT NULL DEFAULT 'synced',
    "items" JSONB NOT NULL,
    "assignedOperatorId" TEXT,
    "stationId" TEXT,
    "awb" TEXT,
    "courier" TEXT,
    "dispatchedAt" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Recording" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "operatorId" TEXT NOT NULL,
    "stationId" TEXT,
    "status" "RecordingStatus" NOT NULL DEFAULT 'started',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "stoppedAt" TIMESTAMP(3),
    "segmentCount" INTEGER NOT NULL DEFAULT 0,
    "b2KeyPrefix" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "orderId" TEXT,
    "mode" "RecordingMode" NOT NULL DEFAULT 'forward',

    CONSTRAINT "Recording_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RecordingSegment" (
    "id" TEXT NOT NULL,
    "recordingId" TEXT NOT NULL,
    "sequence" INTEGER NOT NULL,
    "b2Key" TEXT NOT NULL,
    "checksum" TEXT NOT NULL,
    "sizeBytes" BIGINT NOT NULL,
    "uploadedAt" TIMESTAMP(3),

    CONSTRAINT "RecordingSegment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Return" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "unboxingRecordingId" TEXT,
    "condition" TEXT,
    "decision" TEXT,
    "decidedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Return_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "clerkSessionId" TEXT NOT NULL,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Station" (
    "id" TEXT NOT NULL,
    "warehouseId" TEXT NOT NULL,
    "stationName" TEXT NOT NULL,
    "stationCode" TEXT NOT NULL,
    "cameraConfig" JSONB,
    "scannerConfig" JSONB,
    "printerConfig" JSONB,
    "status" "StationStatus" NOT NULL DEFAULT 'offline',
    "lastHeartbeatAt" TIMESTAMP(3),

    CONSTRAINT "Station_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "firebaseUid" TEXT,
    "companyId" TEXT NOT NULL,
    "employeeId" TEXT,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'packing_operator',
    "warehouseId" TEXT,
    "stationId" TEXT,
    "status" "UserStatus" NOT NULL DEFAULT 'pending',
    "profilePhoto" TEXT,
    "joiningDate" TIMESTAMP(3),
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Warehouse" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "address" JSONB NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "country" TEXT NOT NULL DEFAULT 'India',
    "timezone" TEXT NOT NULL,
    "status" "Status" NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Warehouse_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_identifiers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "identifier_type" "IdentifierType" NOT NULL,
    "identifier_value" TEXT NOT NULL,
    "normalized_value" TEXT NOT NULL,
    "source" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_identifiers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plan_configurations" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "pricePaise" BIGINT NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "billingInterval" TEXT NOT NULL DEFAULT 'MONTHLY',
    "validityMonths" INTEGER NOT NULL DEFAULT 1,
    "includedScans" INTEGER NOT NULL DEFAULT 0,
    "retentionDays" INTEGER NOT NULL DEFAULT 0,
    "storageQuotaBytes" BIGINT NOT NULL DEFAULT 0,
    "maxWarehouses" INTEGER,
    "maxOperators" INTEGER,
    "gstPercent" INTEGER NOT NULL DEFAULT 18,
    "isCommercial" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "plan_configurations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "storage_objects" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "objectType" "StorageObjectType" NOT NULL DEFAULT 'OTHER',
    "bucket" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "contentType" TEXT,
    "sizeBytes" BIGINT NOT NULL DEFAULT 0,
    "originalFileName" TEXT,
    "checksum" TEXT,
    "referenceType" TEXT,
    "referenceId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "storage_objects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "storage_usage_events" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "storageObjectId" TEXT,
    "eventType" "StorageUsageEventType" NOT NULL,
    "sizeBytes" BIGINT NOT NULL,
    "reason" TEXT,
    "idempotencyKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "storage_usage_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "billing_profiles" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "legalName" TEXT NOT NULL,
    "displayName" TEXT,
    "gstin" TEXT,
    "pan" TEXT,
    "addressLine1" TEXT,
    "addressLine2" TEXT,
    "city" TEXT,
    "state" TEXT,
    "stateCode" TEXT,
    "postalCode" TEXT,
    "country" TEXT NOT NULL DEFAULT 'India',
    "billingEmail" TEXT,
    "billingPhone" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "billing_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "invoices_billingPaymentId_unique" ON "invoices"("billingPaymentId") WHERE ("billingPaymentId" IS NOT NULL);

-- CreateIndex
CREATE UNIQUE INDEX "invoices_invoiceNumber_key" ON "invoices"("invoiceNumber");

-- CreateIndex
CREATE INDEX "invoices_companyId_createdAt_idx" ON "invoices"("companyId", "createdAt");

-- CreateIndex
CREATE INDEX "invoices_companyId_status_idx" ON "invoices"("companyId", "status");

-- CreateIndex
CREATE INDEX "invoices_billingPaymentId_idx" ON "invoices"("billingPaymentId");

-- CreateIndex
CREATE INDEX "invoices_pdfStorageKey_idx" ON "invoices"("pdfStorageKey");

-- CreateIndex
CREATE UNIQUE INDEX "invoice_sequences_year_key" ON "invoice_sequences"("year");

-- CreateIndex
CREATE INDEX "invoice_items_invoiceId_idx" ON "invoice_items"("invoiceId");

-- CreateIndex
CREATE INDEX "invoice_items_referenceType_referenceId_idx" ON "invoice_items"("referenceType", "referenceId");

-- CreateIndex
CREATE INDEX "AuditLog_actorId_action_idx" ON "AuditLog"("actorId", "action");

-- CreateIndex
CREATE INDEX "AuditLog_companyId_createdAt_idx" ON "AuditLog"("companyId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "BillingPayment_providerOrderId_key" ON "BillingPayment"("providerOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "BillingPayment_providerPaymentId_key" ON "BillingPayment"("providerPaymentId");

-- CreateIndex
CREATE INDEX "BillingPayment_companyId_idx" ON "BillingPayment"("companyId");

-- CreateIndex
CREATE INDEX "BillingPayment_status_idx" ON "BillingPayment"("status");

-- CreateIndex
CREATE UNIQUE INDEX "BillingSubscription_companyId_key" ON "BillingSubscription"("companyId");

-- CreateIndex
CREATE UNIQUE INDEX "BillingSubscription_razorpaySubId_key" ON "BillingSubscription"("razorpaySubId");

-- CreateIndex
CREATE UNIQUE INDEX "BillingWebhookEvent_provider_eventId_key" ON "BillingWebhookEvent"("provider", "eventId");

-- CreateIndex
CREATE INDEX "Claim_companyId_status_idx" ON "Claim"("companyId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Company_email_key" ON "Company"("email");

-- CreateIndex
CREATE INDEX "Company_status_idx" ON "Company"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Evidence_recordingId_key" ON "Evidence"("recordingId");

-- CreateIndex
CREATE INDEX "Evidence_companyId_idx" ON "Evidence"("companyId");

-- CreateIndex
CREATE INDEX "Evidence_companyId_orderId_idx" ON "Evidence"("companyId", "orderId");

-- CreateIndex
CREATE UNIQUE INDEX "InviteToken_tokenHash_key" ON "InviteToken"("tokenHash");

-- CreateIndex
CREATE UNIQUE INDEX "MarketplaceAccount_companyId_marketplace_key" ON "MarketplaceAccount"("companyId", "marketplace");

-- CreateIndex
CREATE INDEX "Notification_companyId_status_idx" ON "Notification"("companyId", "status");

-- CreateIndex
CREATE INDEX "Order_companyId_createdAt_idx" ON "Order"("companyId", "createdAt");

-- CreateIndex
CREATE INDEX "Order_companyId_status_idx" ON "Order"("companyId", "status");

-- CreateIndex
CREATE INDEX "Order_marketplaceOrderId_idx" ON "Order"("marketplaceOrderId");

-- CreateIndex
CREATE INDEX "Recording_companyId_idx" ON "Recording"("companyId");

-- CreateIndex
CREATE INDEX "Recording_companyId_mode_status_idx" ON "Recording"("companyId", "mode", "status");

-- CreateIndex
CREATE INDEX "Recording_companyId_orderId_status_idx" ON "Recording"("companyId", "orderId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "recording_one_active_per_order_operator" ON "Recording"("companyId", "operatorId", "orderId") WHERE (status = ANY (ARRAY['started'::"RecordingStatus", 'paused'::"RecordingStatus"]));

-- CreateIndex
CREATE UNIQUE INDEX "RecordingSegment_recordingId_sequence_key" ON "RecordingSegment"("recordingId", "sequence");

-- CreateIndex
CREATE UNIQUE INDEX "Return_unboxingRecordingId_key" ON "Return"("unboxingRecordingId");

-- CreateIndex
CREATE INDEX "Return_companyId_idx" ON "Return"("companyId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_clerkSessionId_key" ON "Session"("clerkSessionId");

-- CreateIndex
CREATE INDEX "Session_userId_idx" ON "Session"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Station_warehouseId_stationCode_key" ON "Station"("warehouseId", "stationCode");

-- CreateIndex
CREATE UNIQUE INDEX "User_clerkId_key" ON "User"("firebaseUid");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_companyId_status_idx" ON "User"("companyId", "status");

-- CreateIndex
CREATE INDEX "Warehouse_companyId_status_idx" ON "Warehouse"("companyId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Warehouse_companyId_code_key" ON "Warehouse"("companyId", "code");

-- CreateIndex
CREATE INDEX "order_identifiers_company_normalized_idx" ON "order_identifiers"("company_id", "normalized_value");

-- CreateIndex
CREATE INDEX "order_identifiers_company_type_idx" ON "order_identifiers"("company_id", "identifier_type");

-- CreateIndex
CREATE INDEX "order_identifiers_order_idx" ON "order_identifiers"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_identifiers_company_type_normalized_key" ON "order_identifiers"("company_id", "identifier_type", "normalized_value");

-- CreateIndex
CREATE UNIQUE INDEX "plan_configurations_code_unique" ON "plan_configurations"("code");

-- CreateIndex
CREATE INDEX "plan_configurations_active_idx" ON "plan_configurations"("isActive");

-- CreateIndex
CREATE INDEX "plan_configurations_commercial_active_idx" ON "plan_configurations"("isCommercial", "isActive");

-- CreateIndex
CREATE INDEX "storage_objects_companyId_objectType_idx" ON "storage_objects"("companyId", "objectType");

-- CreateIndex
CREATE INDEX "storage_objects_companyId_createdAt_idx" ON "storage_objects"("companyId", "createdAt");

-- CreateIndex
CREATE INDEX "storage_objects_storageKey_idx" ON "storage_objects"("storageKey");

-- CreateIndex
CREATE INDEX "storage_objects_referenceType_referenceId_idx" ON "storage_objects"("referenceType", "referenceId");

-- CreateIndex
CREATE UNIQUE INDEX "storage_usage_events_idempotencyKey_key" ON "storage_usage_events"("idempotencyKey");

-- CreateIndex
CREATE INDEX "storage_usage_events_companyId_createdAt_idx" ON "storage_usage_events"("companyId", "createdAt");

-- CreateIndex
CREATE INDEX "storage_usage_events_companyId_eventType_idx" ON "storage_usage_events"("companyId", "eventType");

-- CreateIndex
CREATE INDEX "storage_usage_events_storageObjectId_idx" ON "storage_usage_events"("storageObjectId");

-- CreateIndex
CREATE UNIQUE INDEX "billing_profiles_companyId_key" ON "billing_profiles"("companyId");

-- CreateIndex
CREATE INDEX "billing_profiles_gstin_idx" ON "billing_profiles"("gstin");

-- CreateIndex
CREATE INDEX "scan_transactions_type_idx" ON "scan_transactions"("type");

-- CreateIndex
CREATE INDEX "scan_transactions_company_created_idx" ON "scan_transactions"("companyId", "createdAt" DESC);

-- CreateIndex
CREATE INDEX "scan_transactions_wallet_created_idx" ON "scan_transactions"("walletId", "createdAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "scan_transactions_company_idempotency_key" ON "scan_transactions"("companyId", "idempotencyKey") WHERE ("idempotencyKey" IS NOT NULL);

-- AddForeignKey
ALTER TABLE "scan_wallets" ADD CONSTRAINT "scan_wallets_company_fk" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "scan_transactions" ADD CONSTRAINT "scan_transactions_company_fk" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "scan_transactions" ADD CONSTRAINT "scan_transactions_wallet_fk" FOREIGN KEY ("walletId") REFERENCES "scan_wallets"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BillingSubscription" ADD CONSTRAINT "BillingSubscription_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Claim" ADD CONSTRAINT "Claim_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Claim" ADD CONSTRAINT "Claim_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Evidence" ADD CONSTRAINT "Evidence_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MarketplaceAccount" ADD CONSTRAINT "MarketplaceAccount_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Order" ADD CONSTRAINT "Order_warehouseId_fkey" FOREIGN KEY ("warehouseId") REFERENCES "Warehouse"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Recording" ADD CONSTRAINT "Recording_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecordingSegment" ADD CONSTRAINT "RecordingSegment_recordingId_fkey" FOREIGN KEY ("recordingId") REFERENCES "Recording"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Return" ADD CONSTRAINT "Return_unboxingRecordingId_fkey" FOREIGN KEY ("unboxingRecordingId") REFERENCES "Recording"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Station" ADD CONSTRAINT "Station_warehouseId_fkey" FOREIGN KEY ("warehouseId") REFERENCES "Warehouse"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_warehouseId_fkey" FOREIGN KEY ("warehouseId") REFERENCES "Warehouse"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Warehouse" ADD CONSTRAINT "Warehouse_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_identifiers" ADD CONSTRAINT "order_identifiers_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_identifiers" ADD CONSTRAINT "order_identifiers_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shipments" ADD CONSTRAINT "shipments_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_warehouseId_fkey" FOREIGN KEY ("warehouseId") REFERENCES "Warehouse"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage_objects" ADD CONSTRAINT "storage_objects_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage_usage_events" ADD CONSTRAINT "storage_usage_events_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage_usage_events" ADD CONSTRAINT "storage_usage_events_storageObjectId_fkey" FOREIGN KEY ("storageObjectId") REFERENCES "storage_objects"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billing_profiles" ADD CONSTRAINT "billing_profiles_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- RenameIndex
ALTER INDEX "scan_transactions_referenceType_referenceId_idx" RENAME TO "scan_transactions_reference_idx";
