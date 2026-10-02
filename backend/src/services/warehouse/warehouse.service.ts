import { prisma } from "../../config/prisma.js";
import { entitlementService } from "../plans/entitlement.service.js";
export type WarehouseRole =
  | "PLATFORM_ADMIN"
  | "OWNER"
  | "ADMIN"
  | "MANAGER"
  | "OPERATOR"
  | "VIEWER";

export interface WarehouseCreateInput {
  name: string;
  code: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
}

export interface WarehouseUpdateInput {
  name?: string;
  code?: string;
  address?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string;
}

const READ_ROLES: WarehouseRole[] = [
  "PLATFORM_ADMIN",
  "OWNER",
  "ADMIN",
  "MANAGER",
  "OPERATOR",
  "VIEWER",
];

const WRITE_ROLES: WarehouseRole[] = [
  "PLATFORM_ADMIN",
  "OWNER",
  "ADMIN",
];

function normalizeCode(value: string): string {
  return value.trim().toUpperCase();
}

function normalizeOptional(
  value?: string | null,
): string | null | undefined {
  if (value === undefined) {
    return undefined;
  }

  if (value === null) {
    return null;
  }

  const trimmed = value.trim();

  return trimmed.length > 0 ? trimmed : null;
}

export class WarehouseService {
  async getUserContext(firebaseUid: string) {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
      select: {
        id: true,
        companyId: true,
        role: true,
        isActive: true,
        company: {
          select: {
            id: true,
            isActive: true,
          },
        },
      },
    });

    if (!user) {
      throw new Error("USER_NOT_REGISTERED");
    }

    if (!user.isActive || !user.company.isActive) {
      throw new Error("ACCOUNT_DISABLED");
    }

    return user;
  }

  assertRole(
    role: WarehouseRole,
    allowedRoles: WarehouseRole[],
  ): void {
    if (!allowedRoles.includes(role)) {
      throw new Error("FORBIDDEN");
    }
  }

  async list(companyId: string) {
    return prisma.warehouse.findMany({
      where: {
        companyId,
      },
      orderBy: [
        {
          isActive: "desc",
        },
        {
          name: "asc",
        },
      ],
    });
  }

  async getById(
    companyId: string,
    warehouseId: string,
  ) {
    return prisma.warehouse.findFirst({
      where: {
        id: warehouseId,
        companyId,
      },
    });
  }

  async create(
    companyId: string,
    input: WarehouseCreateInput,
  ) {
    const name = input.name.trim();
    const code = normalizeCode(input.code);

    if (!name) {
      throw new Error("WAREHOUSE_NAME_REQUIRED");
    }

    if (!code) {
      throw new Error("WAREHOUSE_CODE_REQUIRED");
    }

    await entitlementService.assertWarehouseCapacity(companyId);
    return prisma.warehouse.create({
      data: {
        companyId,
        name,
        code,
        address: normalizeOptional(input.address),
        city: normalizeOptional(input.city),
        state: normalizeOptional(input.state),
        country: input.country?.trim() || "India",
        isActive: true,
      },
    });
  }

  async update(
    companyId: string,
    warehouseId: string,
    input: WarehouseUpdateInput,
  ) {
    const existing = await this.getById(companyId, warehouseId);

    if (!existing) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const data: {
      name?: string;
      code?: string;
      address?: string | null;
      city?: string | null;
      state?: string | null;
      country?: string;
    } = {};

    if (input.name !== undefined) {
      const name = input.name.trim();

      if (!name) {
        throw new Error("WAREHOUSE_NAME_REQUIRED");
      }

      data.name = name;
    }

    if (input.code !== undefined) {
      const code = normalizeCode(input.code);

      if (!code) {
        throw new Error("WAREHOUSE_CODE_REQUIRED");
      }

      data.code = code;
    }

    if (input.address !== undefined) {
      data.address = normalizeOptional(input.address);
    }

    if (input.city !== undefined) {
      data.city = normalizeOptional(input.city);
    }

    if (input.state !== undefined) {
      data.state = normalizeOptional(input.state);
    }

    if (input.country !== undefined) {
      const country = input.country.trim();

      if (!country) {
        throw new Error("WAREHOUSE_COUNTRY_REQUIRED");
      }

      data.country = country;
    }

    return prisma.warehouse.update({
      where: {
        id: warehouseId,
      },
      data,
    });
  }

  async setStatus(
    companyId: string,
    warehouseId: string,
    isActive: boolean,
  ) {
    const existing = await this.getById(companyId, warehouseId);

    if (!existing) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    return prisma.warehouse.update({
      where: {
        id: warehouseId,
      },
      data: {
        isActive,
      },
    });
  }

  async remove(
    companyId: string,
    warehouseId: string,
  ) {
    const existing = await this.getById(companyId, warehouseId);

    if (!existing) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const [orderCount, sessionCount] = await Promise.all([
      prisma.order.count({
        where: {
          warehouseId,
        },
      }),
      prisma.packingSession.count({
        where: {
          warehouseId,
        },
      }),
    ]);

    if (orderCount > 0 || sessionCount > 0) {
      throw new Error("WAREHOUSE_HAS_DATA");
    }

    return prisma.warehouse.delete({
      where: {
        id: warehouseId,
      },
    });
  }

  async stats(
    companyId: string,
    warehouseId: string,
  ) {
    const warehouse = await this.getById(companyId, warehouseId);

    if (!warehouse) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const activeOrderStatuses = [
      "PENDING",
      "CONFIRMED",
      "PACKING",
      "PACKED",
      "SHIPPED",
    ] as import("../../generated/prisma/enums.js").OrderStatus[];

    const [activeOrders, activeSessions, totalOrders, totalSessions] =
      await Promise.all([
        prisma.order.count({
          where: {
            warehouseId,
            status: { in: activeOrderStatuses },
          },
        }),
        prisma.packingSession.count({
          where: {
            warehouseId,
            status: "ACTIVE",
          },
        }),
        prisma.order.count({
          where: {
            warehouseId,
          },
        }),
        prisma.packingSession.count({
          where: {
            warehouseId,
          },
        }),
      ]);

    return {
      warehouseId: warehouse.id,
      activeOrders,
      activeSessions,
      totalOrders,
      totalSessions,
      status: warehouse.isActive ? "ACTIVE" : "INACTIVE",
    };
  }

  static canRead(role: WarehouseRole): boolean {
    return READ_ROLES.includes(role);
  }

  static canWrite(role: WarehouseRole): boolean {
    return WRITE_ROLES.includes(role);
  }
}
