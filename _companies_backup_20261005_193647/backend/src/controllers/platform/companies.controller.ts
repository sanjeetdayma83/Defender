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

async function requirePlatformAdmin(
  req: AuthenticatedRequest,
  res: Response,
) {
  const uid = req.firebaseUser?.uid;
  if (!uid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
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

    const search =
      typeof req.query.search === "string" ? req.query.search : "";
    const statusRaw =
      typeof req.query.status === "string" ? req.query.status : "all";
    const status =
      statusRaw === "active" || statusRaw === "inactive"
        ? statusRaw
        : "all";

    const plan = typeof req.query.plan === "string" ? req.query.plan : "";
    const region =
      typeof req.query.region === "string" ? req.query.region : "";

    const page = Math.max(Number(req.query.page ?? 1) || 1, 1);
    const limit = Math.min(
      Math.max(Number(req.query.limit ?? 10) || 10, 1),
      100,
    );

    const result = await companiesService.list({
      search,
      status,
      plan,
      region,
      page,
      limit,
    });

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

export async function getPlatformCompany(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const companyId = routeParam(req.params.id).trim();
    if (!companyId) {
      res.status(400).json({
        success: false,
        message: "Company id required.",
      });
      return;
    }

    const result = await companiesService.get(companyId);

    if (!result) {
      res.status(404).json({
        success: false,
        message: "Company not found.",
      });
      return;
    }

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error(
      "getPlatformCompany failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to load company.",
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

    const companyId = routeParam(req.params.id).trim();
    if (!companyId) {
      res.status(400).json({
        success: false,
        message: "Company id required.",
      });
      return;
    }

    const isActive = req.body?.isActive;
    if (typeof isActive !== "boolean") {
      res.status(400).json({
        success: false,
        message: "isActive boolean is required.",
      });
      return;
    }

    const updated = await companiesService.setActive(companyId, isActive);

    res.json({
      success: true,
      data: updated,
    });
  } catch (error) {
    console.error(
      "setCompanyActive failed:",
      error instanceof Error ? error.stack : error,
    );

    const message =
      error instanceof Error && error.message === "COMPANY_NOT_FOUND"
        ? "Company not found."
        : "Unable to update company.";

    res.status(message === "Company not found." ? 404 : 500).json({
      success: false,
      message,
    });
  }
}