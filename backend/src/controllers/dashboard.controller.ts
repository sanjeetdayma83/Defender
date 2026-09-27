import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import { DashboardService } from "../services/dashboard/dashboard.service.js";

const service = new DashboardService();

export async function getDashboardMetrics(
  _req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const metrics = await service.platformMetrics();

    return res.json({
      success: true,
      data: metrics,
    });
  } catch (error) {
    console.error("Dashboard metrics failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to load dashboard metrics.",
    });
  }
}
