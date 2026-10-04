import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../identity/identity.service.js";

const identityService = new IdentityService();

export function isPlatformAdmin(role: unknown): boolean {
  const r = String(role ?? "").toUpperCase().replace(/-/g, "_");
  return r === "PLATFORM_ADMIN" || r === "SUPER_ADMIN";
}

export async function requirePlatformAdmin(req: AuthenticatedRequest, res: Response) {
  const uid = req.firebaseUser?.uid;
  if (!uid) {
    res.status(401).json({ success: false, message: "Authentication required." });
    return null;
  }
  try {
    const user = await identityService.getByFirebaseUid(uid);
    if (!user || !isPlatformAdmin(user.role)) {
      res.status(403).json({ success: false, code: "FORBIDDEN", message: "Platform administrator access required." });
      return null;
    }
    return user;
  } catch (e: any) {
    const msg = String(e?.message ?? e);
    console.error("requirePlatformAdmin:", e);
    if (/ETIMEDOUT|ECONNRESET|closed the connection|Timeout/i.test(msg)) {
      res.status(503).json({ success: false, code: "DB_UNAVAILABLE", message: "Database temporarily unavailable. Retry." });
      return null;
    }
    res.status(500).json({ success: false, message: "Unable to verify administrator." });
    return null;
  }
}
