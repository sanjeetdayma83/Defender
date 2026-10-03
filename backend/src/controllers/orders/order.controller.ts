import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { databaseOrderService } from "../../services/orders/database-order.service.js";
import { scanService } from "../../services/scan/scan.service.js";

export async function listOrders(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);

    const search = String(req.query.search ?? "").trim() || undefined;
    const status = String(req.query.status ?? "").trim() || undefined;

    const orders = await databaseOrderService.list(company.id, search, status);

    res.json({
      success: true,
      data: orders,
    });
  } catch (error) {
    console.error("listOrders failed:", error);
    res.status(500).json({
      success: false,
      message:
        error instanceof Error ? error.message : "Unable to load orders.",
    });
  }
}

export async function getOrder(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);
    const id = String(req.params.id ?? "").trim();

    const order = await databaseOrderService.get(company.id, id);

    if (!order) {
      res.status(404).json({
        success: false,
        message: "Order not found.",
      });
      return;
    }

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error("getOrder failed:", error);
    res.status(500).json({
      success: false,
      message:
        error instanceof Error ? error.message : "Unable to load order.",
    });
  }
}

export async function lookupOrder(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const barcode = String(req.query.barcode ?? req.query.q ?? "").trim();

    if (!barcode) {
      res.status(400).json({
        success: false,
        message: "barcode is required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);
    const result = await scanService.lookup(company.id, barcode);

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("lookupOrder failed:", error);
    res.status(500).json({
      success: false,
      message:
        error instanceof Error ? error.message : "Unable to lookup order.",
    });
  }
}
