import { prisma } from "../../config/prisma.js";

export interface CreateEvidenceInput {
  recordingId: string;
  type: "VIDEO" | "PHOTO";
  fileName?: string;
  storageKey?: string;
  contentType?: string;
  sizeBytes?: number;
  durationSeconds?: number;
  companyId?: string;
}

type EvidenceRow = {
  id: string;
  companyId: string;
  recordingId: string;
  status: string;
  frameCount: number;
  frames: unknown;
  checksum: string | null;
  createdAt: Date;
  orderId: string | null;
};

export class EvidenceService {
  async create(input: CreateEvidenceInput): Promise<EvidenceRow> {
    const recordingRows = await prisma.$queryRawUnsafe<
      Array<{
        id: string;
        companyId: string;
        orderId: string | null;
        status: string;
      }>
    >(
      `
        SELECT
          r.id,
          r."companyId",
          r."orderId",
          r.status::text AS status
        FROM "Recording" r
        WHERE r.id = $1
          AND ($2::text IS NULL OR r."companyId" = $2)
        LIMIT 1
      `,
      input.recordingId,
      input.companyId ?? null,
    );

    const recording = recordingRows[0];

    if (!recording) {
      throw new Error("RECORDING_NOT_FOUND");
    }

    if (!["started", "paused", "completed"].includes(recording.status)) {
      throw new Error("RECORDING_NOT_READY_FOR_EVIDENCE");
    }

    const existingRows = await prisma.$queryRawUnsafe<EvidenceRow[]>(
      `
        SELECT
          e.id,
          e."companyId",
          e."recordingId",
          e.status::text AS status,
          e."frameCount",
          e.frames,
          e.checksum,
          e."createdAt",
          e."orderId"
        FROM "Evidence" e
        WHERE e."recordingId" = $1
          AND ($2::text IS NULL OR e."companyId" = $2)
        LIMIT 1
      `,
      input.recordingId,
      input.companyId ?? null,
    );

    if (existingRows[0]) {
      return existingRows[0];
    }

    const evidenceId = crypto.randomUUID();

    const createdRows = await prisma.$queryRawUnsafe<EvidenceRow[]>(
      `
        INSERT INTO "Evidence"
          ("id", "companyId", "recordingId", "status", "frameCount", "frames", "checksum", "createdAt", "orderId")
        VALUES
          ($1, $2, $3, 'processing'::"EvidenceStatus", 0, '[]'::jsonb, NULL, CURRENT_TIMESTAMP, $4)
        RETURNING
          "id",
          "companyId",
          "recordingId",
          status::text AS status,
          "frameCount",
          frames,
          checksum,
          "createdAt",
          "orderId"
      `,
      evidenceId,
      recording.companyId,
      recording.id,
      recording.orderId,
    );

    const evidence = createdRows[0];

    if (!evidence) {
      throw new Error("EVIDENCE_CREATION_FAILED");
    }

    return evidence;
  }

  async getByAwb(awb: string, companyId: string): Promise<EvidenceRow[]> {
    return prisma.$queryRawUnsafe<EvidenceRow[]>(
      `
        SELECT
          e.id,
          e."companyId",
          e."recordingId",
          e.status::text AS status,
          e."frameCount",
          e.frames,
          e.checksum,
          e."createdAt",
          e."orderId"
        FROM "Evidence" e
        JOIN "Order" o
          ON o.id = e."orderId"
        WHERE e."companyId" = $1
          AND o.awb = $2
        ORDER BY e."createdAt" DESC
      `,
      companyId,
      awb,
    );
  }
}

export const evidenceService = new EvidenceService();


