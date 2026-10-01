import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { scanService } from "../../services/scan/scan.service.js";
import { identityService } from "../../services/identity/identity.service.js";

export async function lookupScan(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const barcode = String(req.body?.barcode ?? "").trim();

    if (!barcode) {
      res.status(400).json({
        success: false,
        message: "Barcode is required.",
      });
      return;
    }

    const identity = await identityService.getByFirebaseUid(firebaseUid);

    const user = {
      companyId: identity.companyId,
      isActive: identity.isActive,
    };

    if (!user) {
      res.status(403).json({
        success: false,
        message: "User identity is not provisioned.",
      });
      return;
    }

    if (!user.isActive) {
      res.status(403).json({
        success: false,
        message: "User account is inactive.",
      });
      return;
    }

    if (!user.companyId) {
      res.status(403).json({
        success: false,
        message: "User is not associated with a company.",
      });
      return;
    }

    const result = await scanService.lookup(user.companyId, barcode);

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to process scan.";

    let statusCode = 400;

    if (message.toLowerCase().includes("ambiguous")) {
      statusCode = 409;
    }

    if (message.toLowerCase().includes("not found")) {
      statusCode = 404;
    }

    res.status(statusCode).json({
      success: false,
      message,
    });
  }
}
