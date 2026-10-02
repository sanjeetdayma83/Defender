import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import { CompanyContextService } from "../services/identity/company-context.service.js";
import { EvidenceService } from "../services/evidence/evidence.service.js";

const service = new EvidenceService();
const companyContextService = new CompanyContextService();

export async function createEvidence(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const {
      recordingId,
      type,
      fileName,
      storageKey,
      contentType,
      sizeBytes,
      durationSeconds,
    } = req.body ?? {};

    if (!recordingId) {
      return res.status(400).json({
        success: false,
        message: "recordingId is required.",
      });
    }

    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      return res.status(401).json({
        success: false,
        message: "Authenticated Firebase user is required.",
      });
    }

    const user = await companyContextService.getUser(firebaseUid);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User identity not found.",
      });
    }

    if (user.status !== "active") {
      return res.status(403).json({
        success: false,
        message: "User is not active.",
      });
    }

    const normalizedType =
      String(type ?? "VIDEO").toUpperCase() === "PHOTO" ? "PHOTO" : "VIDEO";

    const evidence = await service.create({
      recordingId: String(recordingId),
      type: normalizedType,
      fileName: fileName == null ? undefined : String(fileName),
      storageKey: storageKey == null ? undefined : String(storageKey),
      contentType: contentType == null ? undefined : String(contentType),
      sizeBytes: sizeBytes == null ? undefined : Number(sizeBytes),
      durationSeconds:
        durationSeconds == null ? undefined : Number(durationSeconds),
    });

    return res.status(201).json({
      success: true,
      data: evidence,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to create evidence.";

    if (message === "RECORDING_NOT_FOUND") {
      return res.status(404).json({
        success: false,
        message: "Recording not found.",
      });
    }

    if (message === "RECORDING_NOT_READY_FOR_EVIDENCE") {
      return res.status(409).json({
        success: false,
        message: "Recording is not ready for evidence.",
      });
    }

    if (message === "EVIDENCE_CREATION_FAILED") {
      return res.status(500).json({
        success: false,
        message: "Evidence creation failed.",
      });
    }

    return res.status(500).json({
      success: false,
      message,
    });
  }
}

export async function listEvidence(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const awb = String(req.params.awb ?? "").trim();

    if (!awb) {
      return res.status(400).json({
        success: false,
        message: "AWB is required.",
      });
    }

    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      return res.status(401).json({
        success: false,
        message: "Authenticated Firebase user is required.",
      });
    }

    const user = await companyContextService.getUser(firebaseUid);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User identity not found.",
      });
    }

    if (user.status !== "active") {
      return res.status(403).json({
        success: false,
        message: "User is not active.",
      });
    }

    const records = await service.getByAwb(awb, user.companyId);

    return res.json({
      success: true,
      data: records,
      count: records.length,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to fetch evidence.";

    return res.status(500).json({
      success: false,
      message,
    });
  }
}
