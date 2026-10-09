BEGIN;

-- Idempotency belongs to a company, not globally across the platform.
ALTER TABLE "scan_transactions"
  DROP CONSTRAINT IF EXISTS "scan_transactions_idempotencyKey_key";

CREATE UNIQUE INDEX IF NOT EXISTS "scan_transactions_company_idempotency_key"
  ON "scan_transactions" ("companyId", "idempotencyKey")
  WHERE "idempotencyKey" IS NOT NULL;

COMMIT;
