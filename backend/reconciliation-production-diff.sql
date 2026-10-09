-- CreateEnum
CREATE TYPE "ShipmentStatus" AS ENUM ('CREATED', 'READY_TO_PACK', 'PACKING', 'PACKED', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'RETURNED');

-- CreateEnum
CREATE TYPE "PackingSessionStatus" AS ENUM ('ACTIVE', 'COMPLETED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "MediaType" AS ENUM ('VIDEO', 'PHOTO');

-- CreateEnum
CREATE TYPE "StorageObjectType" AS ENUM ('RECORDING', 'EVIDENCE', 'INVOICE', 'DOCUMENT', 'IMAGE', 'VIDEO', 'OTHER');

-- CreateEnum
CREATE TYPE "StorageUsageEventType" AS ENUM ('UPLOAD', 'DELETE', 'RESTORE', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "BillingInterval" AS ENUM ('MONTHLY', 'YEARLY');

-- CreateEnum
CREATE TYPE "SubscriptionProvider" AS ENUM ('MANUAL', 'RAZORPAY', 'STRIPE', 'OTHER');

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
CREATE TYPE "UserRole_new" AS ENUM ('super_admin', 'company_admin', 'warehouse_manager', 'supervisor', 'packing_operator', 'qc_operator', 'claims_executive', 'marketplace_manager', 'viewer', 'auditor');
ALTER TABLE "User" ALTER COLUMN "role" TYPE "UserRole_new" USING ("role"::text::"UserRole_new");
ALTER TYPE "UserRole" RENAME TO "UserRole_old";
ALTER TYPE "UserRole_new" RENAME TO "UserRole";
DROP TYPE "public"."UserRole_old";
COMMIT;

-- DropIndex
DROP INDEX "User_firebaseUid_key";

-- AlterTable
ALTER TABLE "User" DROP COLUMN "role",
ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'packing_operator';

-- DropEnum
DROP TYPE "Role";

-- CreateTable
CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "imageUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "companyId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_variants" (
    "id" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "name" TEXT,
    "variantName" TEXT,
    "color" TEXT,
    "size" TEXT,
    "imageUrl" TEXT,
    "quantity" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "productId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "product_variants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "barcode_aliases" (
    "id" TEXT NOT NULL,
    "barcode" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "productId" TEXT NOT NULL,
    "variantId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "barcode_aliases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unitPrice" DECIMAL(12,2),
    "orderId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "variantId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shipments" (
    "id" TEXT NOT NULL,
    "awb" TEXT NOT NULL,
    "carrier" TEXT,
    "trackingUrl" TEXT,
    "status" "ShipmentStatus" NOT NULL DEFAULT 'CREATED',
    "orderId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "shipments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shipment_barcodes" (
    "id" TEXT NOT NULL,
    "barcode" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "shipmentId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shipment_barcodes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "packing_sessions" (
    "id" TEXT NOT NULL,
    "status" "PackingSessionStatus" NOT NULL DEFAULT 'ACTIVE',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),
    "orderId" TEXT NOT NULL,
    "shipmentId" TEXT NOT NULL,
    "warehouseId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "packing_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "evidence_media" (
    "id" TEXT NOT NULL,
    "type" "MediaType" NOT NULL,
    "status" "EvidenceStatus" NOT NULL DEFAULT 'processing',
    "fileName" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "contentType" TEXT,
    "sizeBytes" BIGINT,
    "durationSeconds" DOUBLE PRECISION,
    "packingSessionId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "evidence_media_pkey" PRIMARY KEY ("id")
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
CREATE INDEX "products_companyId_idx" ON "products"("companyId");

-- CreateIndex
CREATE INDEX "products_sku_idx" ON "products"("sku");

-- CreateIndex
CREATE UNIQUE INDEX "products_companyId_sku_key" ON "products"("companyId", "sku");

-- CreateIndex
CREATE INDEX "product_variants_sku_idx" ON "product_variants"("sku");

-- CreateIndex
CREATE UNIQUE INDEX "product_variants_productId_sku_key" ON "product_variants"("productId", "sku");

-- CreateIndex
CREATE INDEX "barcode_aliases_productId_idx" ON "barcode_aliases"("productId");

-- CreateIndex
CREATE INDEX "barcode_aliases_variantId_idx" ON "barcode_aliases"("variantId");

-- CreateIndex
CREATE UNIQUE INDEX "barcode_aliases_barcode_key" ON "barcode_aliases"("barcode");

-- CreateIndex
CREATE INDEX "order_items_orderId_idx" ON "order_items"("orderId");

-- CreateIndex
CREATE INDEX "order_items_productId_idx" ON "order_items"("productId");

-- CreateIndex
CREATE INDEX "shipments_orderId_idx" ON "shipments"("orderId");

-- CreateIndex
CREATE INDEX "shipments_awb_idx" ON "shipments"("awb");

-- CreateIndex
CREATE UNIQUE INDEX "shipments_awb_key" ON "shipments"("awb");

-- CreateIndex
CREATE INDEX "shipment_barcodes_shipmentId_idx" ON "shipment_barcodes"("shipmentId");

-- CreateIndex
CREATE UNIQUE INDEX "shipment_barcodes_barcode_key" ON "shipment_barcodes"("barcode");

-- CreateIndex
CREATE INDEX "packing_sessions_orderId_idx" ON "packing_sessions"("orderId");

-- CreateIndex
CREATE INDEX "packing_sessions_shipmentId_idx" ON "packing_sessions"("shipmentId");

-- CreateIndex
CREATE INDEX "packing_sessions_userId_idx" ON "packing_sessions"("userId");

-- CreateIndex
CREATE INDEX "packing_sessions_status_idx" ON "packing_sessions"("status");

-- CreateIndex
CREATE INDEX "evidence_media_packingSessionId_idx" ON "evidence_media"("packingSessionId");

-- CreateIndex
CREATE INDEX "evidence_media_type_idx" ON "evidence_media"("type");

-- CreateIndex
CREATE INDEX "evidence_media_status_idx" ON "evidence_media"("status");

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

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_variants" ADD CONSTRAINT "product_variants_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "barcode_aliases" ADD CONSTRAINT "barcode_aliases_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "barcode_aliases" ADD CONSTRAINT "barcode_aliases_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shipments" ADD CONSTRAINT "shipments_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shipment_barcodes" ADD CONSTRAINT "shipment_barcodes_shipmentId_fkey" FOREIGN KEY ("shipmentId") REFERENCES "shipments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_shipmentId_fkey" FOREIGN KEY ("shipmentId") REFERENCES "shipments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_warehouseId_fkey" FOREIGN KEY ("warehouseId") REFERENCES "Warehouse"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "packing_sessions" ADD CONSTRAINT "packing_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evidence_media" ADD CONSTRAINT "evidence_media_packingSessionId_fkey" FOREIGN KEY ("packingSessionId") REFERENCES "packing_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage_objects" ADD CONSTRAINT "storage_objects_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage_usage_events" ADD CONSTRAINT "storage_usage_events_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage_usage_events" ADD CONSTRAINT "storage_usage_events_storageObjectId_fkey" FOREIGN KEY ("storageObjectId") REFERENCES "storage_objects"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billing_profiles" ADD CONSTRAINT "billing_profiles_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;
