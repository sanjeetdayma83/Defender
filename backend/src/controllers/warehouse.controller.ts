import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import {
  WarehouseService,
  type WarehouseCreateInput,
  type WarehouseUpdateInput,
  type WarehouseRole,
} from "../services/warehouse/warehouse.service.js";

const service = new WarehouseService();

function getFirebaseUid(req: AuthenticatedRequest): string {
  const uid = req.firebaseUser?.uid;

  if (!uid) {
    throw new Error("UNAUTHORIZED");
  }

  return uid;
}

async function getUserContext(req: AuthenticatedRequest) {
  const uid = getFirebaseUid(req);
  return service.getUserContext(uid);
}

function getWarehouseId(req: AuthenticatedRequest): string {
  const value = req.params.id;

  if (typeof value !== "string" || !value.trim()) {
    throw new Error("WAREHOUSE_NOT_FOUND");
  }

  return value;
}

function getErrorStatus(error: unknown): number {
  if (!(error instanceof Error)) {
    return 500;
  }

  switch (error.message) {
    case "UNAUTHORIZED":
      return 401;

    case "USER_NOT_REGISTERED":
    case "WAREHOUSE_NOT_FOUND":
      return 404;

    case "ACCOUNT_DISABLED":
    case "FORBIDDEN":
      return 403;

    case "WAREHOUSE_NAME_REQUIRED":
    case "WAREHOUSE_CODE_REQUIRED":
    case "WAREHOUSE_COUNTRY_REQUIRED":
      return 400;

    case "WAREHOUSE_HAS_DATA":
      return 409;

    default:
      return 500;
  }
}

function getErrorMessage(error: unknown): string {
  if (!(error instanceof Error)) {
    return "Unable to process warehouse request.";
  }

  switch (error.message) {
    case "UNAUTHORIZED":
      return "Authentication required.";

    case "USER_NOT_REGISTERED":
      return "User account is not registered.";

    case "ACCOUNT_DISABLED":
      return "Account is disabled.";

    case "FORBIDDEN":
      return "You do not have permission to perform this action.";

    case "WAREHOUSE_NOT_FOUND":
      return "Warehouse not found.";

    case "WAREHOUSE_NAME_REQUIRED":
      return "Warehouse name is required.";

    case "WAREHOUSE_CODE_REQUIRED":
      return "Warehouse code is required.";

    case "WAREHOUSE_COUNTRY_REQUIRED":
      return "Warehouse country is required.";

    case "WAREHOUSE_HAS_DATA":
      return "Warehouse cannot be deleted because it contains operational data.";

    default:
      return "Unable to process warehouse request.";
  }
}

function requireReadRole(role: WarehouseRole): void {
  service.assertRole(role, [
    "PLATFORM_ADMIN",
    "OWNER",
    "ADMIN",
    "MANAGER",
    "OPERATOR",
    "VIEWER",
  ]);
}

function requireWriteRole(role: WarehouseRole): void {
  service.assertRole(role, [
    "PLATFORM_ADMIN",
    "OWNER",
    "ADMIN",
  ]);
}

export async function listWarehouses(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireReadRole(user.role);

    const warehouses = await service.list(user.companyId);

    return res.json({
      success: true,
      data: warehouses,
    });
  } catch (error) {
    console.error("Warehouse listing failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}

export async function getWarehouse(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireReadRole(user.role);

    const warehouseId = getWarehouseId(req);

    const warehouse = await service.getById(
      user.companyId,
      warehouseId,
    );

    if (!warehouse) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    return res.json({
      success: true,
      data: warehouse,
    });
  } catch (error) {
    console.error("Warehouse lookup failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}

export async function createWarehouse(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireWriteRole(user.role);

    const body = req.body as WarehouseCreateInput;

    const warehouse = await service.create(
      user.companyId,
      body,
    );

    return res.status(201).json({
      success: true,
      data: warehouse,
    });
  } catch (error) {
    console.error("Warehouse creation failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}

export async function updateWarehouse(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireWriteRole(user.role);

    const warehouseId = getWarehouseId(req);

    const body = req.body as WarehouseUpdateInput;

    const warehouse = await service.update(
      user.companyId,
      warehouseId,
      body,
    );

    return res.json({
      success: true,
      data: warehouse,
    });
  } catch (error) {
    console.error("Warehouse update failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}

export async function updateWarehouseStatus(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireWriteRole(user.role);

    const warehouseId = getWarehouseId(req);

    const isActive = req.body?.isActive;

    if (typeof isActive !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "isActive must be a boolean.",
      });
    }

    const warehouse = await service.setStatus(
      user.companyId,
      warehouseId,
      isActive,
    );

    return res.json({
      success: true,
      data: warehouse,
    });
  } catch (error) {
    console.error("Warehouse status update failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}

export async function deleteWarehouse(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireWriteRole(user.role);

    const warehouseId = getWarehouseId(req);

    await service.remove(
      user.companyId,
      warehouseId,
    );

    return res.json({
      success: true,
      message: "Warehouse deleted successfully.",
    });
  } catch (error) {
    console.error("Warehouse deletion failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}

export async function getWarehouseStats(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const user = await getUserContext(req);

    requireReadRole(user.role);

    const warehouseId = getWarehouseId(req);

    const stats = await service.stats(
      user.companyId,
      warehouseId,
    );

    return res.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("Warehouse stats failed:", error);

    return res.status(getErrorStatus(error)).json({
      success: false,
      message: getErrorMessage(error),
    });
  }
}
