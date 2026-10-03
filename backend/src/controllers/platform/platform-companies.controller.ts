import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { platformCompaniesService } from "../../services/platform/platform-companies.service.js";

const identityService = new IdentityService();

async function requirePlatformAdmin(req: AuthenticatedRequest, res: Response) {
  const firebaseUid = req.firebaseUser?.uid;
  if (!firebaseUid) {
    res.status(401).json({ success: false, message: "Authentication required." });
    return null;
  }
  const user = await identityService.getByFirebaseUid(firebaseUid);
  if (!user || (user.role !== "PLATFORM_ADMIN" && user.role !== "super_admin")) {
    res.status(403).json({
      success: false,
      code: "FORBIDDEN",
      message: "Platform administrator access required.",
    });
    return null;
  }
  return user;
}

export async function listPlatformCompanies(req: AuthenticatedRequest, res: Response) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const search = typeof req.query.search === "string" ? req.query.search : undefined;
    const activeOnly = req.query.activeOnly === "true";

    const data = await platformCompaniesService.list({ search, activeOnly });

    res.json({ success: true, data });
  } catch (error) {
    console.error("[Platform] list companies failed:", error);
    res.status(500).json({ success: false, message: "Unable to list companies." });
  }
}

export async function setCompanyActive(req: AuthenticatedRequest, res: Response) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const companyId = req.params.companyId?.trim();
    if (!companyId) {
      res.status(400).json({ success: false, message: "companyId is required." });
      return;
    }

    const isActive = req.body?.isActive;
    if (typeof isActive !== "boolean") {
      res.status(400).json({ success: false, message: "isActive boolean is required." });
      return;
    }

    const data = await platformCompaniesService.setActive(companyId, isActive);
    res.json({ success: true, data });
  } catch (error) {
    console.error("[Platform] set company active failed:", error);
    res.status(500).json({ success: false, message: "Unable to update company." });
  }
}

