import type { Response } from "express";

import {
  permissionsForRole,
} from "../../auth/permissions.js";
import {
  toRole,
} from "../../auth/roles.js";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";

const identityService = new IdentityService();

export async function getCurrentUser(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authenticated Firebase user is unavailable.",
      });
      return;
    }

    let user;

    try {
      user = await identityService.getByFirebaseUid(firebaseUid);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);

      if (msg === "USER_NOT_FOUND") {
        res.status(404).json({
          success: false,
          code: "USER_NOT_REGISTERED",
          message: "User profile has not been created in Loss Defender.",
        });
        return;
      }

      throw e;
    }

    if (!user.isActive || !user.company.isActive) {
      res.status(403).json({
        success: false,
        code: "ACCOUNT_DISABLED",
        message: "User or company account is inactive.",
      });
      return;
    }

    const role = toRole(user.role);
    const permissions = permissionsForRole(role);

    res.json({
      success: true,
      data: {
        id: user.id,
        firebaseUid: user.firebaseUid,
        email: user.email,
        name: user.name,
        role,
        permissions,
        isActive: user.isActive,
        company: {
          id: user.company.id,
          name: user.company.name,
          code: user.company.code,
          isActive: user.company.isActive,
        },
        warehouses: user.warehouses,
      },
    });
  } catch (error) {
    console.error("Current user lookup failed:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load current user.",
      detail: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function bootstrapCurrentUser(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authenticated Firebase user is unavailable.",
      });
      return;
    }

    const email = req.firebaseUser?.email?.trim().toLowerCase();

    if (!email) {
      res.status(400).json({
        success: false,
        message: "Firebase account email is required.",
      });
      return;
    }

    const user = await identityService.bootstrapUser({
      firebaseUid,
      email,
      name: req.firebaseUser?.name,
    });

    const role = toRole(user.role);
    const permissions = permissionsForRole(role);

    res.status(201).json({
      success: true,
      data: {
        id: user.id,
        firebaseUid: user.firebaseUid,
        email: user.email,
        name: user.name,
        role,
        permissions,
        company: {
          id: user.company.id,
          name: user.company.name,
          code: user.company.code,
        },
        warehouses: user.warehouses,
      },
    });
  } catch (error) {
    console.error("User bootstrap failed:", error);

    const msg = error instanceof Error ? error.message : String(error);

    if (msg === "USER_NOT_REGISTERED") {
      res.status(404).json({
        success: false,
        code: "USER_NOT_REGISTERED",
        message: "User profile has not been created in Loss Defender.",
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: "Unable to create Loss Defender profile.",
      detail: msg,
    });
  }
}
