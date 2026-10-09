BEGIN;

-- Idempotency belongs to a company, not globally across the platform.
ALTER TABLE "scan_transactions"
  DROP CONSTRAINT IF EXISTS "scan_transactions_idempotencyKey_key";

CREATE UNIQUE INDEX IF NOT EXISTS "scan_transactions_company_idempotency_key"
  ON "scan_transactions" ("companyId", "idempotencyKey")
  WHERE "idempotencyKey" IS NOT NULL;

-- A company/operator/order may have only one active recording.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM "Recording"
    WHERE status IN ('started', 'paused')
    GROUP BY "companyId", "operatorId", "orderId"
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION
      'ACTIVE_RECORDING_DUPLICATES_EXIST: resolve duplicate active recordings before applying this migration';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "recording_one_active_per_order_operator"
  ON "Recording" ("companyId", "operatorId", "orderId")
  WHERE status IN ('started', 'paused');

COMMIT;
