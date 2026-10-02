BEGIN;

CREATE TABLE IF NOT EXISTS "plan_configurations" (
    "id" TEXT PRIMARY KEY,
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
    "isCommercial" BOOLEAN NOT NULL DEFAULT TRUE,
    "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS "plan_configurations_code_unique"
ON "plan_configurations"("code");

CREATE INDEX IF NOT EXISTS "plan_configurations_active_idx"
ON "plan_configurations"("isActive");

CREATE INDEX IF NOT EXISTS "plan_configurations_commercial_active_idx"
ON "plan_configurations"("isCommercial", "isActive");

INSERT INTO "plan_configurations" (
    "id",
    "code",
    "name",
    "description",
    "pricePaise",
    "currency",
    "billingInterval",
    "validityMonths",
    "includedScans",
    "retentionDays",
    "storageQuotaBytes",
    "maxWarehouses",
    "maxOperators",
    "gstPercent",
    "isCommercial",
    "isActive"
)
VALUES
(
    'plan_starter',
    'starter',
    'Starter',
    'Starter warehouse intelligence plan',
    500000,
    'INR',
    'MONTHLY',
    3,
    5100,
    30,
    53687091200,
    1,
    3,
    18,
    TRUE,
    TRUE
),
(
    'plan_growth',
    'growth',
    'Growth',
    'Growth warehouse intelligence plan',
    2000000,
    'INR',
    'MONTHLY',
    6,
    22200,
    30,
    107374182400,
    3,
    10,
    18,
    TRUE,
    TRUE
),
(
    'plan_enterprise',
    'enterprise',
    'Enterprise',
    'Enterprise warehouse intelligence plan',
    4500000,
    'INR',
    'MONTHLY',
    12,
    56200,
    30,
    536870912000,
    NULL,
    NULL,
    18,
    TRUE,
    TRUE
)
ON CONFLICT ("code") DO UPDATE SET
    "name" = EXCLUDED."name",
    "description" = EXCLUDED."description",
    "pricePaise" = EXCLUDED."pricePaise",
    "currency" = EXCLUDED."currency",
    "billingInterval" = EXCLUDED."billingInterval",
    "validityMonths" = EXCLUDED."validityMonths",
    "includedScans" = EXCLUDED."includedScans",
    "retentionDays" = EXCLUDED."retentionDays",
    "storageQuotaBytes" = EXCLUDED."storageQuotaBytes",
    "maxWarehouses" = EXCLUDED."maxWarehouses",
    "maxOperators" = EXCLUDED."maxOperators",
    "gstPercent" = EXCLUDED."gstPercent",
    "isCommercial" = EXCLUDED."isCommercial",
    "isActive" = EXCLUDED."isActive",
    "updatedAt" = CURRENT_TIMESTAMP;

COMMIT;
