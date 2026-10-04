import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { PlatformSubscriptionsService } from "../../services/platform/platform-subscriptions.service.js";

const identityService = new IdentityService();
const subscriptionsService = new PlatformSubscriptionsService();

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

export async function listPlatformSubscriptions(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const search = typeof req.query.search === "string" ? req.query.search : "";
    const status =
      typeof req.query.status === "string" ? req.query.status : "all";
    const limit = Number(req.query.limit ?? 100);

    const result = await subscriptionsService.list({ search, status, limit });
    res.json({ success: true, data: result });
  } catch (error) {
    console.error(
      "listPlatformSubscriptions failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to load subscriptions.",
    });
  }
}



