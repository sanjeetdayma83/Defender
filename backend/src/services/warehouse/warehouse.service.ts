import { randomUUID } from "node:crypto";
import { Prisma } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

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

function clean(value?: string | null): string {
  return typeof value === "string" ? value.trim() : "";
}

function mapWarehouse(row: any) {
  const status = String(row.status ?? "").toLowerCase();

  return {
    id: String(row.id),
    companyId: String(row.companyId),
    name: String(row.name ?? ""),
    code: String(row.code ?? ""),
    address: row.address ?? {},
    city: String(row.city ?? ""),
    state: String(row.state ?? ""),
    country: String(row.country ?? "India"),
    timezone: String(row.timezone ?? "Asia/Kolkata"),
    status: row.status,
    isActive: status === "active",
    createdAt: row.createdAt,
  };
}

export class WarehouseService {
  async getUserContext(firebaseUid: string) {
    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        u.id,
        u."firebaseUid",
        u.email,
        u.name,
        u."companyId",
        u.role::text AS role,
        u.status::text AS status,
        c.status::text AS "companyStatus"
      FROM "User" u
      LEFT JOIN "Company" c
        ON c.id = u."companyId"
      WHERE u."firebaseUid" = ${firebaseUid}
      LIMIT 1
    `);

    if (!rows.length) {
      throw new Error("USER_NOT_REGISTERED");
    }

    const row = rows[0];
    const userStatus = String(row.status ?? "").toLowerCase();
    const companyStatus =
      String(row.companyStatus ?? "").toLowerCase();

    if (
      userStatus !== "active" ||
      companyStatus !== "active"
    ) {
      throw new Error("ACCOUNT_DISABLED");
    }

    return {
      id: row.id,
      firebaseUid: row.firebaseUid,
      email: row.email,
      name: row.name,
      companyId: row.companyId,
      role: (() => {
        const rawRole = String(row.role ?? "")
          .trim()
          .toLowerCase()
          .replace(/-/g, "_");

        switch (rawRole) {
          case "super_admin":
          case "platform_admin":
            return "PLATFORM_ADMIN" as WarehouseRole;

          case "company_admin":
          case "owner":
            return "OWNER" as WarehouseRole;

          case "admin":
            return "ADMIN" as WarehouseRole;

          case "warehouse_manager":
          case "manager":
            return "MANAGER" as WarehouseRole;

          case "packing_operator":
          case "operator":
          case "qc_operator":
            return "OPERATOR" as WarehouseRole;

          case "viewer":
          case "auditor":
            return "VIEWER" as WarehouseRole;

          default:
            return rawRole.toUpperCase() as WarehouseRole;
        }
      })(),
      isActive: true,
    };
  }

  assertRole(
    role: WarehouseRole,
    allowedRoles: WarehouseRole[],
  ): void {
    if (!allowedRoles.includes(role)) {
      throw new Error("FORBIDDEN");
    }
  }

  private async rows(companyId: string) {
    return prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        w.id,
        w."companyId",
        w.name,
        w.code,
        w.address,
        w.city,
        w.state,
        w.country,
        w.timezone,
        w.status::text AS status,
        w."createdAt"
      FROM "Warehouse" w
      WHERE w."companyId" = ${companyId}
      ORDER BY
        CASE
          WHEN w.status::text = 'active' THEN 0
          ELSE 1
        END,
        w.name ASC
    `);
  }

  async list(companyId: string) {
    const rows = await this.rows(companyId);
    return rows.map(mapWarehouse);
  }

  async getById(
    companyId: string,
    warehouseId: string,
  ) {
    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        w.id,
        w."companyId",
        w.name,
        w.code,
        w.address,
        w.city,
        w.state,
        w.country,
        w.timezone,
        w.status::text AS status,
        w."createdAt"
      FROM "Warehouse" w
      WHERE
        w.id = ${warehouseId}
        AND w."companyId" = ${companyId}
      LIMIT 1
    `);

    return rows.length ? mapWarehouse(rows[0]) : null;
  }

  async create(
    companyId: string,
    input: WarehouseCreateInput,
  ) {
    const name = clean(input.name);
    const code = normalizeCode(input.code);

    if (!name) {
      throw new Error("WAREHOUSE_NAME_REQUIRED");
    }

    if (!code) {
      throw new Error("WAREHOUSE_CODE_REQUIRED");
    }

    const duplicate = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id
      FROM "Warehouse"
      WHERE
        "companyId" = ${companyId}
        AND code = ${code}
      LIMIT 1
    `);

    if (duplicate.length) {
      throw new Error("WAREHOUSE_CODE_EXISTS");
    }

    const warehouseId = randomUUID();

    const address = JSON.stringify({
      line1: clean(input.address),
      city: clean(input.city),
      state: clean(input.state),
      country: clean(input.country) || "India",
    });

    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      INSERT INTO "Warehouse" (
        id,
        "companyId",
        name,
        code,
        address,
        city,
        state,
        country,
        timezone,
        status,
        "createdAt"
      )
      VALUES (
        ${warehouseId},
        ${companyId},
        ${name},
        ${code},
        ${address}::jsonb,
        ${clean(input.city)},
        ${clean(input.state)},
        ${clean(input.country) || "India"},
        'Asia/Kolkata',
        'active'::"Status",
        NOW()
      )
      RETURNING
        id,
        "companyId",
        name,
        code,
        address,
        city,
        state,
        country,
        timezone,
        status::text AS status,
        "createdAt"
    `);

    return mapWarehouse(rows[0]);
  }

  async update(
    companyId: string,
    warehouseId: string,
    input: WarehouseUpdateInput,
  ) {
    const existing = await this.getById(
      companyId,
      warehouseId,
    );

    if (!existing) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const name =
      input.name === undefined
        ? existing.name
        : clean(input.name);

    const code =
      input.code === undefined
        ? existing.code
        : normalizeCode(input.code);

    if (!name) {
      throw new Error("WAREHOUSE_NAME_REQUIRED");
    }

    if (!code) {
      throw new Error("WAREHOUSE_CODE_REQUIRED");
    }

    const duplicate = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id
      FROM "Warehouse"
      WHERE
        "companyId" = ${companyId}
        AND code = ${code}
        AND id <> ${warehouseId}
      LIMIT 1
    `);

    if (duplicate.length) {
      throw new Error("WAREHOUSE_CODE_EXISTS");
    }

    const address =
      input.address === undefined
        ? existing.address
        : {
            line1: clean(input.address),
            city:
              input.city === undefined
                ? existing.city
                : clean(input.city),
            state:
              input.state === undefined
                ? existing.state
                : clean(input.state),
            country:
              input.country === undefined
                ? existing.country
                : clean(input.country) || "India",
          };

    const city =
      input.city === undefined
        ? existing.city
        : clean(input.city);

    const state =
      input.state === undefined
        ? existing.state
        : clean(input.state);

    const country =
      input.country === undefined
        ? existing.country
        : clean(input.country) || "India";

    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      UPDATE "Warehouse"
      SET
        name = ${name},
        code = ${code},
        address = ${JSON.stringify(address)}::jsonb,
        city = ${city},
        state = ${state},
        country = ${country},
        "timezone" = 'Asia/Kolkata'
      WHERE
        id = ${warehouseId}
        AND "companyId" = ${companyId}
      RETURNING
        id,
        "companyId",
        name,
        code,
        address,
        city,
        state,
        country,
        timezone,
        status::text AS status,
        "createdAt"
    `);

    return mapWarehouse(rows[0]);
  }

  async setStatus(
    companyId: string,
    warehouseId: string,
    isActive: boolean,
  ) {
    const existing = await this.getById(
      companyId,
      warehouseId,
    );

    if (!existing) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const status = isActive ? "active" : "suspended";

    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      UPDATE "Warehouse"
      SET status = ${status}::"Status"
      WHERE
        id = ${warehouseId}
        AND "companyId" = ${companyId}
      RETURNING
        id,
        "companyId",
        name,
        code,
        address,
        city,
        state,
        country,
        timezone,
        status::text AS status,
        "createdAt"
    `);

    return mapWarehouse(rows[0]);
  }

  async remove(
    companyId: string,
    warehouseId: string,
  ) {
    const existing = await this.getById(
      companyId,
      warehouseId,
    );

    if (!existing) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const orderRows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT COUNT(*)::int AS count
      FROM "Order"
      WHERE "warehouseId" = ${warehouseId}
    `);

    let sessionCount = 0;

    try {
      const sessionRows = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT COUNT(*)::int AS count
        FROM "PackingSession"
        WHERE "warehouseId" = ${warehouseId}
      `);

      sessionCount = Number(sessionRows[0]?.count ?? 0);
    } catch (_) {
      sessionCount = 0;
    }

    const orderCount = Number(
      orderRows[0]?.count ?? 0,
    );

    if (orderCount > 0 || sessionCount > 0) {
      throw new Error("WAREHOUSE_HAS_DATA");
    }

    await prisma.$executeRaw(Prisma.sql`
      DELETE FROM "Warehouse"
      WHERE
        id = ${warehouseId}
        AND "companyId" = ${companyId}
    `);

    return true;
  }

  async stats(
    companyId: string,
    warehouseId: string,
  ) {
    const warehouse = await this.getById(
      companyId,
      warehouseId,
    );

    if (!warehouse) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const orderRows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        COUNT(*)::int AS total_orders,
        COUNT(*) FILTER (
          WHERE lower(status::text) IN (
            'queued',
            'packing',
            'recording',
            'synced'
          )
        )::int AS active_orders
      FROM "Order"
      WHERE "warehouseId" = ${warehouseId}
    `);

    let totalSessions = 0;
    let activeSessions = 0;

    try {
      const sessionRows = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT
          COUNT(*)::int AS total_sessions,
          COUNT(*) FILTER (
            WHERE lower(status::text) = 'active'
          )::int AS active_sessions
        FROM "PackingSession"
        WHERE "warehouseId" = ${warehouseId}
      `);

      totalSessions =
        Number(sessionRows[0]?.total_sessions ?? 0);
      activeSessions =
        Number(sessionRows[0]?.active_sessions ?? 0);
    } catch (_) {}

    return {
      warehouseId,
      activeOrders:
        Number(orderRows[0]?.active_orders ?? 0),
      activeSessions,
      totalOrders:
        Number(orderRows[0]?.total_orders ?? 0),
      totalSessions,
      status: warehouse.isActive
        ? "ACTIVE"
        : "INACTIVE",
    };
  }

  static canRead(role: WarehouseRole): boolean {
    return READ_ROLES.includes(role);
  }

  static canWrite(role: WarehouseRole): boolean {
    return WRITE_ROLES.includes(role);
  }
}
