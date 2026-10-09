BEGIN;

-- Fail early if the required legacy dependency or enum types are missing.
DO $$
BEGIN
  IF to_regclass('public.orders') IS NULL THEN
    RAISE EXCEPTION 'RECORDING_PREREQUISITE_MISSING: public.orders';
  END IF;

  IF to_regtype('public."RecordingStatus"') IS NULL THEN
    RAISE EXCEPTION 'RECORDING_PREREQUISITE_MISSING: RecordingStatus enum';
  END IF;

  IF to_regtype('public."RecordingMode"') IS NULL THEN
    RAISE EXCEPTION 'RECORDING_PREREQUISITE_MISSING: RecordingMode enum';
  END IF;

  IF to_regclass('public."Recording"') IS NOT NULL
     OR to_regclass('public."RecordingSegment"') IS NOT NULL
     OR to_regclass('public."Return"') IS NOT NULL THEN
    RAISE EXCEPTION 'RECORDING_FOUNDATION_CONFLICT: one or more target tables already exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'RecordingStatus'
      AND e.enumlabel = 'started'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'RecordingStatus'
      AND e.enumlabel = 'paused'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'RecordingStatus'
      AND e.enumlabel = 'completed'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'RecordingStatus'
      AND e.enumlabel = 'failed'
  ) THEN
    RAISE EXCEPTION 'RECORDING_PREREQUISITE_MISSING: expected RecordingStatus labels';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'RecordingMode'
      AND e.enumlabel = 'forward'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'RecordingMode'
      AND e.enumlabel = 'return'
  ) THEN
    RAISE EXCEPTION 'RECORDING_PREREQUISITE_MISSING: expected RecordingMode labels';
  END IF;
END $$;

CREATE TABLE public."Recording" (
  "id" TEXT NOT NULL,
  "companyId" TEXT NOT NULL,
  "operatorId" TEXT NOT NULL,
  "stationId" TEXT,
  "status" public."RecordingStatus" NOT NULL DEFAULT 'started',
  "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "stoppedAt" TIMESTAMP(3),
  "segmentCount" INTEGER NOT NULL DEFAULT 0,
  "b2KeyPrefix" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "orderId" TEXT,
  "mode" public."RecordingMode" NOT NULL DEFAULT 'forward',
  CONSTRAINT "Recording_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "Recording_orderId_fkey"
    FOREIGN KEY ("orderId") REFERENCES public.orders("id")
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "Recording_companyId_idx"
  ON public."Recording" ("companyId");

CREATE INDEX "Recording_companyId_mode_status_idx"
  ON public."Recording" ("companyId", "mode", "status");

CREATE INDEX "Recording_companyId_orderId_status_idx"
  ON public."Recording" ("companyId", "orderId", "status");

CREATE UNIQUE INDEX "recording_one_active_per_order_operator"
  ON public."Recording" ("companyId", "operatorId", "orderId")
  WHERE "status" IN ('started', 'paused');

CREATE TABLE public."RecordingSegment" (
  "id" TEXT NOT NULL,
  "recordingId" TEXT NOT NULL,
  "sequence" INTEGER NOT NULL,
  "b2Key" TEXT NOT NULL,
  "checksum" TEXT NOT NULL,
  "sizeBytes" BIGINT NOT NULL,
  "uploadedAt" TIMESTAMP(3),
  CONSTRAINT "RecordingSegment_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "RecordingSegment_recordingId_fkey"
    FOREIGN KEY ("recordingId") REFERENCES public."Recording"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "RecordingSegment_recordingId_sequence_key"
  ON public."RecordingSegment" ("recordingId", "sequence");

CREATE TABLE public."Return" (
  "id" TEXT NOT NULL,
  "companyId" TEXT NOT NULL,
  "orderId" TEXT NOT NULL,
  "unboxingRecordingId" TEXT,
  "condition" TEXT,
  "decision" TEXT,
  "decidedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Return_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "Return_unboxingRecordingId_fkey"
    FOREIGN KEY ("unboxingRecordingId") REFERENCES public."Recording"("id")
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "Return_unboxingRecordingId_key"
  ON public."Return" ("unboxingRecordingId");

CREATE INDEX "Return_companyId_idx"
  ON public."Return" ("companyId");

COMMIT;