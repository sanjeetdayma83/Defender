import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { databaseOrderService } from "../../services/orders/database-order.service.js";
import { scanService } from "../../services/scan/scan.service.js";

export async function listOrders(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
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
}

export async function getOrder(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const firebaseUid = req.firebaseUser?.uid;

  if (!firebaseUid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  const { company } = await companyContextService.getCompany(firebaseUid);

  const order = await databaseOrderService.get(
    company.id,
    String(req.params.id),
  );

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
}

export async function lookupOrder(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const firebaseUid = req.firebaseUser?.uid;

  if (!firebaseUid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  const value = String(req.query.barcode ?? req.query.identifier ?? "").trim();

  if (!value) {
    res.status(400).json({
      success: false,
      message: "barcode or identifier is required.",
    });
    return;
  }

  const { company } = await companyContextService.getCompany(firebaseUid);

  try {
    const result = await scanService.lookup(company.id, value);

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Barcode, AWB, order ID or SKU was not found.";

    const status =
      message.toLowerCase().includes("ambiguous")
        ? 409
        : 404;

    res.status(status).json({
      success: false,
      code: status === 409 ? "AMBIGUOUS_SCAN" : "ORDER_NOT_FOUND",
      message,
    });
  }
}


