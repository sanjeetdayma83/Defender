import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import {
  orderImportService,
  type ImportMapping,
} from "../../services/imports/order-import.service.js";

function canImport(role?: string): boolean {
  return ["OWNER", "ADMIN", "MANAGER"].includes(role ?? "");
}

function getFile(req: AuthenticatedRequest) {
  return req.file;
}

function parseMapping(value: unknown): ImportMapping | undefined {
  if (!value) return undefined;

  if (typeof value === "object") {
    return value as ImportMapping;
  }

  if (typeof value === "string") {
    try {
      return JSON.parse(value) as ImportMapping;
    } catch {
      return undefined;
    }
  }

  return undefined;
}

export async function previewImport(
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

  const { user } = await companyContextService.getCompany(firebaseUid);

  if (!canImport(user.role)) {
    res.status(403).json({
      success: false,
      message: "You do not have permission to import orders.",
    });
    return;
  }

  const file = getFile(req);

  if (!file) {
    res.status(400).json({
      success: false,
      message: "CSV/XLSX file is required.",
    });
    return;
  }

  try {
    const validation = orderImportService.parse(file.buffer, file.originalname);

    res.json({
      success: true,
      data: {
        fileName: file.originalname,
        headers: validation.headers,
        mapping: validation.mapping,
        totalRows: validation.rows.length,
        valid: validation.valid,
        issues: validation.issues,
        duplicates: validation.duplicates,
        previewRows: validation.rows.slice(0, 50),
      },
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message:
        error instanceof Error ? error.message : "Unable to read import file.",
    });
  }
}

export async function importOrders(
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

  const { user, company } = await companyContextService.getCompany(firebaseUid);

  if (!canImport(user.role)) {
    res.status(403).json({
      success: false,
      message: "You do not have permission to import orders.",
    });
    return;
  }

  const file = getFile(req);

  if (!file) {
    res.status(400).json({
      success: false,
      message: "CSV/XLSX file is required.",
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

  const warehouse = await import("../../generated/prisma/client.js")
    .then(() => companyContextService)
    .then(async () => {
      const { prisma } = await import("../../config/prisma.js");

      return prisma.warehouse.findFirst({
        where: {
          id: warehouseId,
          companyId: company.id,
          isActive: true,
        },
      });
    });

  if (!warehouse) {
    res.status(404).json({
      success: false,
      message: "Warehouse not found for this company.",
    });
    return;
  }

  try {
    const validation = orderImportService.parse(file.buffer, file.originalname);

    const mapping = parseMapping(req.body?.mapping);

    if (mapping) {
      // Mapping is accepted by the API contract.
      // Automatic mapping remains the default parser behaviour.
    }

    if (!validation.valid) {
      res.status(422).json({
        success: false,
        code: "IMPORT_VALIDATION_FAILED",
        data: {
          headers: validation.headers,
          mapping: validation.mapping,
          totalRows: validation.rows.length,
          issues: validation.issues,
          duplicates: validation.duplicates,
        },
      });
      return;
    }

    const result = await orderImportService.import(
      company.id,
      warehouse.id,
      validation,
    );

    res.status(201).json({
      success: true,
      message: "Orders imported successfully.",
      data: result,
    });
  } catch (error) {
    if (
      error instanceof Error &&
      error.message === "IMPORT_VALIDATION_FAILED"
    ) {
      res.status(422).json({
        success: false,
        code: "IMPORT_VALIDATION_FAILED",
        message: "Import validation failed.",
      });
      return;
    }

    throw error;
  }
}
