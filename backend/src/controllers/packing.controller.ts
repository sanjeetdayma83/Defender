import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import { PackingService } from "../services/packing/packing.service.js";
import { CompanyContextService } from "../services/identity/company-context.service.js";

const service = new PackingService();
const companyContextService = new CompanyContextService();

export async function startPacking(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { awb, warehouseId } = req.body ?? {};

    if (!awb || !warehouseId) {
      res.status(400).json({
        success: false,
        message: "awb and warehouseId are required.",
      });
      return;
    }

    if (!req.firebaseUser?.uid) {
      res.status(401).json({
        success: false,
        message: "Authenticated Firebase user is required.",
      });
      return;
    }

    const session = await service.start({
      awb: String(awb),
      warehouseId: String(warehouseId),
      firebaseUid: req.firebaseUser.uid,
      email: req.firebaseUser.email,
      name: req.firebaseUser.name,
    });

    res.status(201).json({
      success: true,
      data: session,
    });
  } catch (error) {
    console.error("Packing session start failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to start packing session.";

    const status =
      message.includes("not found") ||
      message.includes("does not belong") ||
      message.includes("inactive")
        ? 404
        : 400;

    res.status(status).json({
      success: false,
      message,
    });
  }
}

export async function getPacking(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const id = String(req.params.id ?? "");

    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);

    const session = await service.get(id, company.id);

    if (!session) {
      res.status(404).json({
        success: false,
        message: "Packing session not found.",
      });
      return;
    }

    res.json({
      success: true,
      data: session,
    });
  } catch (error) {
    console.error("Packing session lookup failed:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load packing session.",
    });
  }
}

export async function completePacking(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const id = String(req.params.id ?? "");

    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);

    const session = await service.complete(id, company.id);

    res.json({
      success: true,
      data: session,
    });
  } catch (error) {
    console.error("Packing completion failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to complete packing session.";

    res.status(message.includes("not found") ? 404 : 400).json({
      success: false,
      message,
    });
  }
}

export async function cancelPacking(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const id = String(req.params.id ?? "");

    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);

    const session = await service.cancel(id, company.id);

    res.json({
      success: true,
      data: session,
    });
  } catch (error) {
    console.error("Packing cancellation failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to cancel packing session.";

    res.status(message.includes("not found") ? 404 : 400).json({
      success: false,
      message,
    });
  }
}

export async function getPackingByShipment(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const shipmentId = String(req.params.shipmentId ?? "");

    if (!shipmentId) {
      res.status(400).json({
        success: false,
        message: "Shipment ID is required.",
      });
      return;
    }

    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);
    const sessions = await service.getByShipment(shipmentId, company.id);

    res.json({
      success: true,
      data: sessions,
      count: sessions.length,
    });
  } catch (error) {
    console.error("Shipment packing sessions lookup failed:", error);

    res.status(500).json({
      success: false,
      message: "Unable to load packing sessions.",
    });
  }
}


