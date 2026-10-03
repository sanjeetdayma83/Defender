import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { DashboardService } from "../../services/dashboard/dashboard.service.js";

const identityService = new IdentityService();
const dashboardService = new DashboardService();

export async function getCompanyDashboard(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const user = await identityService.getByFirebaseUid(firebaseUid);

    if (!user) {
      res.status(404).json({
        success: false,
        code: "USER_NOT_REGISTERED",
        message: "User profile not found.",
      });
      return;
    }

    if (!user.isActive || !user.company.isActive) {
      res.status(403).json({
        success: false,
        code: "ACCOUNT_DISABLED",
        message: "Account is inactive.",
      });
      return;
    }

    const metrics = await dashboardService.companyMetrics(user.companyId);

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
        },
        company: {
          id: user.company.id,
          name: user.company.name,
          code: user.company.code,
        },
        metrics,
      },
    });
  } catch (error) {
    console.error("Company dashboard failed:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load dashboard.",
    });
  }
}

export async function getPlatformDashboard(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const user = await identityService.getByFirebaseUid(firebaseUid);

    const roleNorm = String(user?.role ?? "").toUpperCase().replace(/-/g, "_");
    if (!user || (roleNorm !== "PLATFORM_ADMIN" && roleNorm !== "SUPER_ADMIN")) {
      res.status(403).json({
        success: false,
        code: "FORBIDDEN",
        message: "Platform administrator access required.",
      });
      return;
    }

    const metrics = await dashboardService.platformMetrics();

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
        },
        metrics,
      },
    });
  } catch (error) {
    console.error("Platform dashboard failed:", error instanceof Error ? error.stack : error);

    res.status(500).json({
      success: false,
      message: "Unable to load platform dashboard.",
    });
  }
}


