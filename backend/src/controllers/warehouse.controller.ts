import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import { WarehouseService } from "../services/users/user.service.js";

const service = new WarehouseService();

export async function listWarehouses(
  _req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const warehouses = await service.list();

    return res.json({
      success: true,
      data: warehouses,
    });
  } catch (error) {
    console.error("Warehouse listing failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to load warehouses.",
    });
  }
}
