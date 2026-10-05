import type { Response } from "express";
import { routeParam } from "./route-param.js";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { PlatformCompaniesService } from "../../services/platform/platform-companies.service.js";

const identityService = new IdentityService();
const companiesService = new PlatformCompaniesService();

function isPlatformAdmin(role: unknown): boolean {
  const r = String(role ?? "").toUpperCase().replace(/-/g, "_");
  return r === "PLATFORM_ADMIN" || r === "SUPER_ADMIN";
}

async function requirePlatformAdmin(req: AuthenticatedRequest, res: Response) {
  const uid = req.firebaseUser?.uid;
  if (!uid) {
    res.status(401).json({ success: false, message: "Authentication required." });
    return null;
  }
  const user = await identityService.getByFirebaseUid(uid);
  if (!user || !isPlatformAdmin(user.role)) {
    res.status(403).json({
      success: false,
      code: "FORBIDDEN",
      message: "Platform administrator access required.",
    });
    return null;
  }
  return user;
}

export async function listPlatformCompanies(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const search = typeof req.query.search === "string" ? req.query.search : "";
    const statusRaw =
      typeof req.query.status === "string" ? req.query.status : "all";
    const status =
      statusRaw === "active" || statusRaw === "inactive" ? statusRaw : "all";
    const limit = Number(req.query.limit ?? 50);

    const result = await companiesService.list({ search, status, limit });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error(
      "listPlatformCompanies failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to load companies.",
    });
  }
}

export async function setCompanyActive(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const companyId = routeParam(req.params.id);
    const isActive = Boolean(req.body?.isActive);

    if (!companyId) {
      res.status(400).json({ success: false, message: "Company id required." });
      return;
    }

    const updated = await companiesService.setActive(companyId, isActive);
    res.json({ success: true, data: updated });
  } catch (error) {
    console.error(
      "setCompanyActive failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to update company.",
    });
  }
}
