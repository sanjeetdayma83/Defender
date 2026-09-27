import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { databaseOrderService } from "../../services/orders/database-order.service.js";
import { scanLookupService } from "../../services/scan/scan-lookup.service.js";

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

  const result = await scanLookupService.lookup(company.id, value);

  if (!result.found) {
    res.status(result.ambiguous ? 409 : 404).json({
      success: false,
      code: result.ambiguous ? "AMBIGUOUS_SCAN" : "ORDER_NOT_FOUND",
      data: result,
    });
    return;
  }

  res.json({
    success: true,
    data: result,
  });
}
