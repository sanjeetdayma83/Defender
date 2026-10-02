import type { Response } from "express";
import { entitlementService } from "../../services/plans/entitlement.service.js";
import { randomUUID, createHash } from "node:crypto";
import {
  DeleteObjectCommand,
  PutObjectCommand,
  S3Client,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { prisma } from "../../config/prisma.js";
import { b2Config } from "../../config/b2.config.js";

const s3 = new S3Client({
  region: b2Config.region,
  endpoint: b2Config.endpoint,
  credentials: {
    accessKeyId: b2Config.keyId,
    secretAccessKey: b2Config.applicationKey,
  },
});

function requireFirebaseUid(req: AuthenticatedRequest): string {
  const uid = req.firebaseUser?.uid;

  if (!uid) {
    throw new Error("AUTHENTICATION_REQUIRED");
  }

  return uid;
}

function sanitizeFileName(fileName: string): string {
  const normalized = fileName
    .normalize("NFKD")
    .replace(/[^\w.\-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

  return normalized || "file";
}

function getObjectType(
  value: unknown,
): "EVIDENCE" | "INVOICE" | "CREDIT_NOTE" | "EXPORT" | "OTHER" {
  const normalized = String(value ?? "EVIDENCE").toUpperCase();

  if (
    normalized === "INVOICE" ||
    normalized === "CREDIT_NOTE" ||
    normalized === "EXPORT" ||
    normalized === "OTHER"
  ) {
    return normalized;
  }

  return "EVIDENCE";
}

function jsonSafe<T>(value: T): T {
  return JSON.parse(
    JSON.stringify(value, (_key, currentValue) =>
      typeof currentValue === "bigint"
        ? currentValue.toString()
        : currentValue,
    ),
  ) as T;
}

async function getCompanyContext(req: AuthenticatedRequest) {
  const firebaseUid = requireFirebaseUid(req);
  return companyContextService.getCompany(firebaseUid);
}

async function validateRecording(
  recordingId: string,
  companyId: string,
) {
  const rows = await prisma.$queryRawUnsafe<Array<{
    id: string;
    companyId: string;
    operatorId: string;
    orderId: string | null;
    status: string;
    mode: string;
    segmentCount: number;
    b2KeyPrefix: string | null;
  }>>(
    `
      SELECT
        r.id,
        r."companyId",
        r."operatorId",
        r."orderId",
        r.status::text AS status,
        r.mode::text AS mode,
        r."segmentCount",
        r."b2KeyPrefix"
      FROM "Recording" r
      WHERE r.id = $1
        AND r."companyId" = $2
      LIMIT 1
    `,
    recordingId,
    companyId,
  );

  const recording = rows[0];

  if (!recording) {
    throw new Error("RECORDING_NOT_FOUND");
  }

  if (!["started", "paused"].includes(recording.status)) {
    throw new Error("RECORDING_NOT_ACTIVE");
  }

  return recording;
}

async function uploadEvidence(
  req: AuthenticatedRequest,
  res: Response,
  mediaType: "VIDEO" | "PHOTO",
): Promise<void> {
  let storageKey = "";

  try {
    const { company } = await getCompanyContext(req);

    const file = req.file;

    if (!file) {
      res.status(400).json({
        success: false,
        message: "File is required. Use multipart/form-data field 'file'.",
      });
      return;
    }

    const recordingId = String(
      req.body?.recordingId ?? "",
    ).trim();

    if (!recordingId) {
      res.status(400).json({
        success: false,
        message: "recordingId is required.",
      });
      return;
    }

    const session = await validateRecording(
      recordingId,
      company.id,
    );

    const originalFileName = file.originalname || "file";
    const safeFileName = sanitizeFileName(originalFileName);

    const extension =
      safeFileName.includes(".")
        ? safeFileName.substring(safeFileName.lastIndexOf("."))
        : "";

    const date = new Date().toISOString().slice(0, 10);

    storageKey = [
      company.id,
      "evidence",
      mediaType.toLowerCase(),
      date,
      `${randomUUID()}${extension}`,
    ].join("/");

    const checksum = createHash("sha256")
      .update(file.buffer)
      .digest("hex");

    await entitlementService.assertStorageCapacity(company.id, file.size);
    await s3.send(
      new PutObjectCommand({
        Bucket: b2Config.bucketName,
        Key: storageKey,
        Body: file.buffer,
        ContentType: file.mimetype || "application/octet-stream",
        Metadata: {
          companyId: company.id,
          recordingId: session.id,
          mediaType,
          originalFileName: safeFileName,
          checksum,
        },
      }),
    );

    const idempotencyHeader =
      req.headers["idempotency-key"] ??
      req.headers["x-idempotency-key"];

    const idempotencyKey = Array.isArray(idempotencyHeader)
      ? idempotencyHeader[0]
      : idempotencyHeader;

    const result = await prisma.$transaction(async (tx) => {
      const lockedRows = await tx.$queryRawUnsafe<Array<{
        id: string;
        companyId: string;
        orderId: string | null;
        segmentCount: number;
      }>>(
        `
          SELECT
            r.id,
            r."companyId",
            r."orderId",
            r."segmentCount"
          FROM "Recording" r
          WHERE r.id = $1
            AND r."companyId" = $2
          FOR UPDATE
        `,
        recordingId,
        company.id,
      );

      const recording = lockedRows[0];

      if (!recording) {
        throw new Error("RECORDING_NOT_FOUND");
      }

      const sequence = recording.segmentCount + 1;
      const segmentId = randomUUID();

      const segment = await tx.$queryRawUnsafe<Array<{
        id: string;
        recordingId: string;
        sequence: number;
        b2Key: string;
        checksum: string;
        sizeBytes: bigint;
        uploadedAt: Date | null;
      }>>(
        `
          INSERT INTO "RecordingSegment"
            ("id", "recordingId", "sequence", "b2Key", "checksum", "sizeBytes", "uploadedAt")
          VALUES
            ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
          RETURNING
            "id",
            "recordingId",
            "sequence",
            "b2Key",
            "checksum",
            "sizeBytes",
            "uploadedAt"
        `,
        segmentId,
        recording.id,
        sequence,
        storageKey,
        checksum,
        BigInt(file.size),
      );

      await tx.$executeRawUnsafe(
        `
          UPDATE "Recording"
          SET "segmentCount" = $1
          WHERE id = $2
            AND "companyId" = $3
        `,
        sequence,
        recording.id,
        company.id,
      );

      await tx.$executeRawUnsafe(
        `
          UPDATE "Company"
          SET
            "storageUsed" = COALESCE("storageUsed", 0) + $1,
            "updatedAt" = CURRENT_TIMESTAMP
          WHERE id = $2
        `,
        BigInt(file.size),
        company.id,
      );


      return {
        recording,
        segment: segment[0],
      };
    });

    res.status(201).json({
      success: true,
      data: jsonSafe({
        id: result.segment.id,
        type: mediaType,
        status: "uploaded",
        fileName: originalFileName,
        storageKey: result.segment.b2Key,
        contentType: file.mimetype || null,
        sizeBytes: result.segment.sizeBytes,
        recordingId: result.segment.recordingId,
        sequence: result.segment.sequence,
        checksum: result.segment.checksum,
        uploadedAt: result.segment.uploadedAt,
      }),
    });
  } catch (error) {
    console.error(
      `${mediaType} storage upload failed:`,
      error,
    );

    if (storageKey) {
      try {
        await s3.send(
          new DeleteObjectCommand({
            Bucket: b2Config.bucketName,
            Key: storageKey,
          }),
        );
      } catch (cleanupError) {
        console.error(
          "Failed to clean up uploaded B2 object:",
          cleanupError,
        );
      }
    }

    const message =
      error instanceof Error
        ? error.message
        : String(error);

    if (message === "USER_NOT_FOUND") {
      res.status(404).json({
        success: false,
        message: "Authenticated user is not registered.",
      });
      return;
    }

    if (message === "USER_INACTIVE") {
      res.status(403).json({
        success: false,
        message: "User account is inactive.",
      });
      return;
    }

    if (message === "COMPANY_INACTIVE") {
      res.status(403).json({
        success: false,
        message: "Company account is inactive.",
      });
      return;
    }

    if (message === "RECORDING_NOT_FOUND") {
      res.status(404).json({
        success: false,
        message: "Packing session not found for your company.",
      });
      return;
    }

    if (message.includes("Unique constraint")) {
      res.status(409).json({
        success: false,
        message: "This upload has already been processed.",
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: "Unable to upload file.",
    });
  }

}
export async function uploadRecording(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  await uploadEvidence(req, res, "VIDEO");
}

export async function uploadPhoto(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  await uploadEvidence(req, res, "PHOTO");
}

export async function getMediaUrl(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { company } = await getCompanyContext(req);

    const storageKey = String(
      req.query.storageKey ?? "",
    ).trim();

    if (!storageKey) {
      res.status(400).json({
        success: false,
        message: "storageKey is required.",
      });
      return;
    }

    const storageObject = await prisma.storageObject.findFirst({
      where: {
        companyId: company.id,
        storageKey,
      },
      select: {
        id: true,
        bucket: true,
        storageKey: true,
        contentType: true,
        sizeBytes: true,
        originalFileName: true,
        createdAt: true,
      },
    });

    if (!storageObject) {
      res.status(404).json({
        success: false,
        message: "Storage object not found.",
      });
      return;
    }

    const command = new GetObjectCommand({
      Bucket: storageObject.bucket,
      Key: storageObject.storageKey,
    });

    const expiresIn = Math.max(
      1,
      Math.min(
        Number.isFinite(b2Config.signedUrlTtl)
          ? b2Config.signedUrlTtl
          : 900,
        86400,
      ),
    );

    const url = await getSignedUrl(s3, command, {
      expiresIn,
    });

    res.json({
      success: true,
      data: {
        url,
        expiresIn,
        storageKey: storageObject.storageKey,
        contentType: storageObject.contentType,
        sizeBytes: storageObject.sizeBytes.toString(),
        originalFileName: storageObject.originalFileName,
        createdAt: storageObject.createdAt,
      },
    });
  } catch (error) {
    console.error("Media URL generation failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to generate media URL.";

    if (message === "AUTHENTICATION_REQUIRED") {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: "Unable to generate media URL.",
    });
  }
}

export async function getEvidence(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { company } = await getCompanyContext(req);

    const awb = String(req.params.awb ?? "").trim();

    if (!awb) {
      res.status(400).json({
        success: false,
        message: "AWB is required.",
      });
      return;
    }

    const records = await prisma.evidenceMedia.findMany({
      where: {
        packingSession: {
          shipment: {
            awb,
          },
          order: {
            companyId: company.id,
          },
        },
      },
      include: {
        packingSession: {
          select: {
            id: true,
            status: true,
            startedAt: true,
            completedAt: true,
            orderId: true,
            shipmentId: true,
            warehouseId: true,
            userId: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    res.json({
      success: true,
      data: jsonSafe(records),
      count: records.length,
    });
  } catch (error) {
    console.error("Evidence lookup failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to load evidence.";

    if (message === "AUTHENTICATION_REQUIRED") {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: "Unable to load evidence.",
    });
  }
}

export async function getStorageUsage(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { company } = await getCompanyContext(req);

    const [aggregate, grouped, objectCount] = await Promise.all([
      prisma.storageObject.aggregate({
        where: {
          companyId: company.id,
        },
        _sum: {
          sizeBytes: true,
        },
      }),

      prisma.storageObject.groupBy({
        by: ["objectType"],
        where: {
          companyId: company.id,
        },
        _count: {
          _all: true,
        },
        _sum: {
          sizeBytes: true,
        },
      }),

      prisma.storageObject.count({
        where: {
          companyId: company.id,
        },
      }),
    ]);

    const totalBytes = aggregate._sum.sizeBytes ?? BigInt(0);

    res.json({
      success: true,
      data: {
        companyId: company.id,
        totalObjects: objectCount,
        totalBytes: totalBytes.toString(),
        totalGB: Number(totalBytes) / 1024 / 1024 / 1024,
        byType: grouped.map((item) => ({
          objectType: item.objectType,
          objectCount: item._count._all,
          sizeBytes: (item._sum.sizeBytes ?? BigInt(0)).toString(),
          sizeGB:
            Number(item._sum.sizeBytes ?? BigInt(0)) /
            1024 /
            1024 /
            1024,
        })),
      },
    });
  } catch (error) {
    console.error("Storage usage lookup failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to load storage usage.";

    if (message === "AUTHENTICATION_REQUIRED") {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: "Unable to load storage usage.",
    });
  }
}









