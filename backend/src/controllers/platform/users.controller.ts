import type { Response } from "express";
import { routeParam } from "./route-param.js";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { PlatformUsersService } from "../../services/platform/platform-users.service.js";

const identityService = new IdentityService();
const usersService = new PlatformUsersService();

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

export async function listPlatformUsers(
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
    const role = typeof req.query.role === "string" ? req.query.role : "";
    const limit = Number(req.query.limit ?? 100);

    const result = await usersService.list({ search, status, role, limit });
    res.json({ success: true, data: result });
  } catch (error) {
    console.error(
      "listPlatformUsers failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to load users.",
    });
  }
}

export async function setUserStatus(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const userId = routeParam(req.params.id);
    const isActive = Boolean(req.body?.isActive);

    if (!userId) {
      res.status(400).json({ success: false, message: "User id required." });
      return;
    }

    // Prevent self-lockout
    if (admin.id === userId && !isActive) {
      res.status(400).json({
        success: false,
        message: "Cannot suspend your own account.",
      });
      return;
    }

    const updated = await usersService.setStatus(userId, isActive);
    res.json({ success: true, data: updated });
  } catch (error) {
    console.error(
      "setUserStatus failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to update user.",
    });
  }
}
