import type { Response } from "express";
import { routeParam } from "./route-param.js";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { PlatformPlansService } from "../../services/platform/platform-plans.service.js";

const identityService = new IdentityService();
const plansService = new PlatformPlansService();

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

export async function listPlatformPlans(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const activeOnly = req.query.active === "true";
    const limit = Number(req.query.limit ?? 100);
    const result = await plansService.list({ activeOnly, limit });
    res.json({ success: true, data: result });
  } catch (error) {
    console.error(
      "listPlatformPlans failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({ success: false, message: "Unable to load plans." });
  }
}

export async function createPlatformPlan(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const body = req.body ?? {};
    const created = await plansService.create({
      code: String(body.code ?? ""),
      name: String(body.name ?? ""),
      description: body.description != null ? String(body.description) : undefined,
      pricePaise: body.pricePaise != null ? Number(body.pricePaise) : undefined,
      currency: body.currency != null ? String(body.currency) : undefined,
      billingInterval:
        body.billingInterval != null ? String(body.billingInterval) : undefined,
      validityMonths:
        body.validityMonths != null ? Number(body.validityMonths) : undefined,
      includedScans:
        body.includedScans != null ? Number(body.includedScans) : undefined,
      retentionDays:
        body.retentionDays != null ? Number(body.retentionDays) : undefined,
      storageQuotaBytes:
        body.storageQuotaBytes != null
          ? Number(body.storageQuotaBytes)
          : undefined,
      maxWarehouses:
        body.maxWarehouses != null ? Number(body.maxWarehouses) : undefined,
      maxOperators:
        body.maxOperators != null ? Number(body.maxOperators) : undefined,
      gstPercent: body.gstPercent != null ? Number(body.gstPercent) : undefined,
      isCommercial:
        body.isCommercial != null ? Boolean(body.isCommercial) : undefined,
      isActive: body.isActive != null ? Boolean(body.isActive) : undefined,
    });

    res.status(201).json({ success: true, data: created });
  } catch (error) {
    console.error(
      "createPlatformPlan failed:",
      error instanceof Error ? error.stack : error,
    );
    const msg =
      error instanceof Error ? error.message : "Unable to create plan.";
    res.status(400).json({ success: false, message: msg });
  }
}

export async function updatePlatformPlan(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const id = routeParam(req.params.id);
    if (!id) {
      res.status(400).json({ success: false, message: "Plan id required." });
      return;
    }

    const body = req.body ?? {};
    const updated = await plansService.update(id, {
      name: body.name != null ? String(body.name) : undefined,
      description:
        body.description !== undefined
          ? body.description == null
            ? null
            : String(body.description)
          : undefined,
      pricePaise: body.pricePaise != null ? Number(body.pricePaise) : undefined,
      currency: body.currency != null ? String(body.currency) : undefined,
      billingInterval:
        body.billingInterval != null ? String(body.billingInterval) : undefined,
      validityMonths:
        body.validityMonths != null ? Number(body.validityMonths) : undefined,
      includedScans:
        body.includedScans != null ? Number(body.includedScans) : undefined,
      retentionDays:
        body.retentionDays != null ? Number(body.retentionDays) : undefined,
      storageQuotaBytes:
        body.storageQuotaBytes !== undefined
          ? body.storageQuotaBytes == null
            ? null
            : Number(body.storageQuotaBytes)
          : undefined,
      maxWarehouses:
        body.maxWarehouses != null ? Number(body.maxWarehouses) : undefined,
      maxOperators:
        body.maxOperators != null ? Number(body.maxOperators) : undefined,
      gstPercent: body.gstPercent != null ? Number(body.gstPercent) : undefined,
      isCommercial:
        body.isCommercial != null ? Boolean(body.isCommercial) : undefined,
      isActive: body.isActive != null ? Boolean(body.isActive) : undefined,
    });

    res.json({ success: true, data: updated });
  } catch (error) {
    console.error(
      "updatePlatformPlan failed:",
      error instanceof Error ? error.stack : error,
    );
    const msg =
      error instanceof Error ? error.message : "Unable to update plan.";
    const code = msg === "PLAN_NOT_FOUND" ? 404 : 400;
    res.status(code).json({ success: false, message: msg });
  }
}

export async function setPlanActive(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const id = routeParam(req.params.id);
    const isActive = Boolean(req.body?.isActive);
    if (!id) {
      res.status(400).json({ success: false, message: "Plan id required." });
      return;
    }

    const updated = await plansService.setActive(id, isActive);
    res.json({ success: true, data: updated });
  } catch (error) {
    console.error(
      "setPlanActive failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({ success: false, message: "Unable to update plan." });
  }
}
