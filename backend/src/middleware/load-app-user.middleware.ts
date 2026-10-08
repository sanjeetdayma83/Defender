import type { NextFunction, Response } from "express";

import type { AuthorizedRequest } from "./authorize.js";
import { IdentityService } from "../services/identity/identity.service.js";
import { permissionsForRole } from "../auth/permissions.js";
import { toRole } from "../auth/roles.js";
import type { AppUser } from "../auth/app-user.js";

const identityService = new IdentityService();

export async function loadAppUser(
  req: AuthorizedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        code: "AUTH_CONTEXT_MISSING",
        message: "Firebase authentication is required.",
      });
      return;
    }

    const user = await identityService.getByFirebaseUid(firebaseUid);
    const role = toRole(user.role);

    if (!user.isActive) {
      res.status(403).json({
        success: false,
        code: "ACCOUNT_SUSPENDED",
        message: "Your account is inactive.",
      });
      return;
    }

    if (!user.company.isActive) {
      res.status(403).json({
        success: false,
        code: "COMPANY_SUSPENDED",
        message: "Your company account is inactive.",
      });
      return;
    }

    /*
     * IMPORTANT:
     * The current database still has legacy warehouse relationships.
     * Until user_warehouse_assignments is migrated, we do NOT claim
     * warehouse-level isolation here.
     *
     * Seller/platform roles receive company warehouse IDs.
     * Warehouse-scoped enforcement will be activated in Phase 2
     * after the assignment table is introduced.
     */
    const warehouseIds = Array.isArray(user.warehouses)
      ? user.warehouses
          .filter((warehouse: any) => warehouse?.id)
          .map((warehouse: any) => String(warehouse.id))
      : [];

    const appUser: AppUser = {
      id: String(user.id),
      firebaseUid: String(user.firebaseUid),
      email: String(user.email),
      name: user.name ? String(user.name) : null,
      phone: user.phone ? String(user.phone) : null,

      role,
      permissions: permissionsForRole(role),

      companyId: user.companyId ? String(user.companyId) : null,
      warehouseIds,

      isActive: Boolean(user.isActive),
      companyIsActive: Boolean(user.company.isActive),
    };

    req.appUser = appUser;

    next();
  } catch (error) {
    const code =
      error instanceof Error && "code" in error
        ? String((error as { code?: unknown }).code)
        : undefined;

    if (code === "ROLE_UNKNOWN") {
      res.status(403).json({
        success: false,
        code: "ROLE_UNKNOWN",
        message: "Your account has an unsupported role.",
      });
      return;
    }

    console.error("loadAppUser failed:", error);

    res.status(500).json({
      success: false,
      code: "IDENTITY_CONTEXT_FAILED",
      message: "Unable to load authorization context.",
    });
  }
}
