import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { orderImportService } from "../../services/imports/order-import.service.js";
import { orderImportLiveService } from "../../services/imports/order-import-live.service.js";

export async function previewOrdersImport(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    if (!req.file) {
      res.status(400).json({
        success: false,
        message: "CSV or XLSX file is required.",
      });
      return;
    }

    const parsed = orderImportService.parse(
      req.file.buffer,
      req.file.originalname,
    );

    res.json({
      success: true,
      data: parsed,
    });
  } catch (error) {
    console.error("Order import preview failed:", error);
    res.status(400).json({
      success: false,
      message:
        error instanceof Error
          ? error.message
          : "Unable to preview import file.",
    });
  }
}

export async function importOrders(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    if (!req.file) {
      res.status(400).json({
        success: false,
        message: "CSV or XLSX file is required.",
      });
      return;
    }

    const warehouseId = String(req.body?.warehouseId ?? "").trim();

    if (!warehouseId) {
      res.status(400).json({
        success: false,
        message: "warehouseId is required.",
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

    const parsed = orderImportService.parse(
      req.file.buffer,
      req.file.originalname,
    );

    if (!parsed.valid) {
      res.status(422).json({
        success: false,
        code: "IMPORT_VALIDATION_FAILED",
        message: "Import file contains validation errors.",
        data: parsed,
      });
      return;
    }

    const result = await orderImportLiveService.import(
      company.id,
      warehouseId,
      parsed as any,
    );

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Order import failed:", error);
    res.status(400).json({
      success: false,
      message:
        error instanceof Error ? error.message : "Unable to import orders.",
    });
  }
}
