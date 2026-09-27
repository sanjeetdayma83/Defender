import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import { EvidenceService } from "../services/evidence/evidence.service.js";

const service = new EvidenceService();

export async function createEvidence(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const {
      packingSessionId,
      type,
      fileName,
      storageKey,
      contentType,
      sizeBytes,
      durationSeconds,
    } = req.body ?? {};

    if (!packingSessionId || !fileName || !storageKey) {
      res.status(400).json({
        success: false,
        message: "packingSessionId, fileName and storageKey are required.",
      });
      return;
    }

    const normalizedType =
      String(type ?? "VIDEO").toUpperCase() === "PHOTO" ? "PHOTO" : "VIDEO";

    const evidence = await service.create({
      packingSessionId: String(packingSessionId),
      type: normalizedType,
      fileName: String(fileName),
      storageKey: String(storageKey),
      contentType: contentType == null ? undefined : String(contentType),
      sizeBytes: sizeBytes == null ? undefined : Number(sizeBytes),
      durationSeconds:
        durationSeconds == null ? undefined : Number(durationSeconds),
    });

    res.status(201).json({
      success: true,
      data: evidence,
    });
  } catch (error) {
    console.error("Evidence creation failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to create evidence record.";

    res.status(message.includes("not found") ? 404 : 400).json({
      success: false,
      message,
    });
  }
}

export async function listEvidence(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const awb = String(req.params.awb ?? "").trim();

    if (!awb) {
      res.status(400).json({
        success: false,
        message: "AWB is required.",
      });
      return;
    }

    const records = await service.getByAwb(awb);

    res.json({
      success: true,
      data: records,
      count: records.length,
    });
  } catch (error) {
    console.error("Evidence lookup failed:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load evidence.",
    });
  }
}
