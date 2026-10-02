-- Loss Defender Pro
-- Controlled additive invoice foundation for the legacy/live billing schema.
-- DO NOT run through Prisma migrate against the live database.
-- This migration intentionally does not depend on the new Payment or StorageObject models.

CREATE TABLE IF NOT EXISTS "invoice_sequences" (
    "id" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "nextValue" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "invoice_sequences_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "invoice_sequences_year_key" UNIQUE ("year")
);

CREATE TABLE IF NOT EXISTS "invoices" (
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

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "invoices_invoiceNumber_key" UNIQUE ("invoiceNumber"),
    CONSTRAINT "invoices_companyId_fkey"
        FOREIGN KEY ("companyId") REFERENCES "Company"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "invoice_items" (
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

    CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "invoice_items_invoiceId_fkey"
        FOREIGN KEY ("invoiceId") REFERENCES "invoices"("id")
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "invoices_companyId_createdAt_idx"
    ON "invoices"("companyId", "createdAt");

CREATE INDEX IF NOT EXISTS "invoices_companyId_status_idx"
    ON "invoices"("companyId", "status");

CREATE INDEX IF NOT EXISTS "invoices_billingPaymentId_idx"
    ON "invoices"("billingPaymentId");

CREATE INDEX IF NOT EXISTS "invoices_pdfStorageKey_idx"
    ON "invoices"("pdfStorageKey");

CREATE INDEX IF NOT EXISTS "invoice_items_invoiceId_idx"
    ON "invoice_items"("invoiceId");

CREATE INDEX IF NOT EXISTS "invoice_items_referenceType_referenceId_idx"
    ON "invoice_items"("referenceType", "referenceId");
