import { randomUUID } from "node:crypto";
import { Prisma } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

type SetupInput = {
  name?: unknown;
  email?: unknown;
  phone?: unknown;
  companyName?: unknown;
  address?: unknown;
  city?: unknown;
  state?: unknown;
  pin?: unknown;
  warehouseName?: unknown;
  warehouseCode?: unknown;
};

function clean(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function makeCode(value: string, fallback: string): string {
  const generated = clean(value)
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 30);
  return generated || fallback;
}

function warehouseAddress(address: string, city: string, state: string, pin = ""): string {
  return [address, city, state, pin, "India"].filter(Boolean).join(", ");
}

export class OnboardingService {
  private async findUser(firebaseUid: string) {
    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        u.id,
        u."firebaseUid",
        u."companyId",
        u.name,
        u.email,
        u.role::text AS role,
        u."isActive" AS "userIsActive",
        c.name AS "companyName",
        c.code AS "companyCode",
        c."isActive" AS "companyIsActive"
      FROM public.users u
      LEFT JOIN public.companies c ON c.id = u."companyId"
      WHERE u."firebaseUid" = ${firebaseUid}
      LIMIT 1
    `);
    return rows[0] ?? null;
  }

  private async getWarehouses(companyId: string) {
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
        w."isActive" AS "isActive",
        w."createdAt"
      FROM public.warehouses w
      WHERE w."companyId" = ${companyId}
      ORDER BY w."createdAt" ASC, w.name ASC
    `);
  }

  async getStatus(firebaseUid: string) {
    const user = await this.findUser(firebaseUid);
    if (!user) {
      return { exists: false, complete: false, user: null, company: null, warehouses: [] };
    }

    const warehouses = await this.getWarehouses(user.companyId);
    const complete = clean(user.name).length > 0 && clean(user.companyName).length > 0 && warehouses.length > 0;

    return {
      exists: true,
      complete,
      user: {
        id: user.id,
        firebaseUid: user.firebaseUid,
        name: user.name,
        email: user.email,
        phone: null,
        role: user.role,
        status: user.userIsActive ? "ACTIVE" : "INACTIVE",
      },
      company: {
        id: user.companyId,
        name: user.companyName,
        code: user.companyCode ?? "",
        email: null,
        phone: null,
        address: null,
        plan: null,
        isActive: Boolean(user.companyIsActive),
      },
      warehouses: warehouses.map((w: any) => ({
        ...w,
        timezone: "Asia/Kolkata",
        status: w.isActive ? "ACTIVE" : "INACTIVE",
        isActive: Boolean(w.isActive),
      })),
    };
  }

  async updateProfile(firebaseUid: string, input: { name?: unknown }) {
    const user = await this.findUser(firebaseUid);
    if (!user) throw new Error("USER_NOT_FOUND");
    const name = clean(input.name);
    if (!name) throw new Error("NAME_REQUIRED");

    await prisma.$executeRaw(Prisma.sql`
      UPDATE public.users
      SET name = ${name}, "updatedAt" = NOW()
      WHERE id = ${user.id}
    `);
    return this.getStatus(firebaseUid);
  }

  async updateCompany(
    firebaseUid: string,
    input: { name?: unknown; phone?: unknown; address?: unknown; city?: unknown; state?: unknown; pin?: unknown },
  ) {
    const user = await this.findUser(firebaseUid);
    if (!user) throw new Error("USER_NOT_FOUND");
    const name = clean(input.name);
    if (!name) throw new Error("COMPANY_NAME_REQUIRED");

    const code = makeCode(name, "COMPANY");
    await prisma.$executeRaw(Prisma.sql`
      UPDATE public.companies
      SET name = ${name}, code = COALESCE(code, ${code}), "updatedAt" = NOW()
      WHERE id = ${user.companyId}
    `);
    return this.getStatus(firebaseUid);
  }

  async createWarehouse(
    firebaseUid: string,
    input: { name?: unknown; code?: unknown; address?: unknown; city?: unknown; state?: unknown },
  ) {
    const user = await this.findUser(firebaseUid);
    if (!user) throw new Error("USER_NOT_FOUND");
    const name = clean(input.name);
    if (!name) throw new Error("WAREHOUSE_NAME_REQUIRED");
    const code = makeCode(clean(input.code), makeCode(name, "WAREHOUSE"));

    const existing = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id, name, code
      FROM public.warehouses
      WHERE "companyId" = ${user.companyId} AND code = ${code}
      LIMIT 1
    `);
    if (existing.length) {
      if (clean(existing[0].name).toLowerCase() !== name.toLowerCase()) {
        throw new Error("WAREHOUSE_CODE_EXISTS");
      }
      return existing[0];
    }

    const id = randomUUID();
    const address = warehouseAddress(clean(input.address), clean(input.city), clean(input.state));
    await prisma.$executeRaw(Prisma.sql`
      INSERT INTO public.warehouses (
        id, "companyId", name, code, address, city, state, country, "isActive", "createdAt", "updatedAt"
      ) VALUES (
        ${id}, ${user.companyId}, ${name}, ${code}, ${address},
        ${clean(input.city) || null}, ${clean(input.state) || null}, 'India', TRUE, NOW(), NOW()
      )
    `);
    return { id, companyId: user.companyId, name, code, address, isActive: true };
  }

  async complete(firebaseUid: string, input: SetupInput) {
    const name = clean(input.name);
    const email = clean(input.email).toLowerCase();
    const companyName = clean(input.companyName);
    const address = clean(input.address);
    const city = clean(input.city);
    const state = clean(input.state);
    const pin = clean(input.pin);
    const warehouseName = clean(input.warehouseName);
    const requestedWarehouseCode = clean(input.warehouseCode);

    if (!name) throw new Error("NAME_REQUIRED");
    if (!email) throw new Error("EMAIL_REQUIRED");
    if (!companyName) throw new Error("COMPANY_NAME_REQUIRED");
    if (!address) throw new Error("ADDRESS_REQUIRED");
    if (!city) throw new Error("CITY_REQUIRED");
    if (!state) throw new Error("STATE_REQUIRED");
    if (!pin) throw new Error("PIN_REQUIRED");
    if (!warehouseName) throw new Error("WAREHOUSE_NAME_REQUIRED");

    const existingUser = await this.findUser(firebaseUid);
    const warehouseCodeBase = makeCode(requestedWarehouseCode, makeCode(warehouseName, "WAREHOUSE"));
    const fullAddress = warehouseAddress(address, city, state, pin);

    if (existingUser) {
      const existingWarehouse = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT id, code, name FROM public.warehouses
        WHERE "companyId" = ${existingUser.companyId}
        ORDER BY "createdAt" ASC LIMIT 1
      `);
      let warehouseCode = warehouseCodeBase;
      const codeConflict = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT id, name FROM public.warehouses
        WHERE "companyId" = ${existingUser.companyId} AND code = ${warehouseCode}
        LIMIT 1
      `);
      if (codeConflict.length && clean(codeConflict[0].name).toLowerCase() !== warehouseName.toLowerCase()) {
        throw new Error("WAREHOUSE_CODE_EXISTS");
      }

      await prisma.$transaction(async (tx) => {
        await tx.$executeRaw(Prisma.sql`
          UPDATE public.users SET name = ${name}, "isActive" = TRUE, "updatedAt" = NOW()
          WHERE id = ${existingUser.id}
        `);
        await tx.$executeRaw(Prisma.sql`
          UPDATE public.companies SET name = ${companyName}, "isActive" = TRUE, "updatedAt" = NOW()
          WHERE id = ${existingUser.companyId}
        `);
        if (existingWarehouse.length) {
          await tx.$executeRaw(Prisma.sql`
            UPDATE public.warehouses
            SET name = ${warehouseName}, code = ${warehouseCode}, address = ${fullAddress},
                city = ${city}, state = ${state}, country = 'India', "isActive" = TRUE, "updatedAt" = NOW()
            WHERE id = ${existingWarehouse[0].id}
          `);
        } else {
          await tx.$executeRaw(Prisma.sql`
            INSERT INTO public.warehouses (
              id, "companyId", name, code, address, city, state, country, "isActive", "createdAt", "updatedAt"
            ) VALUES (
              ${randomUUID()}, ${existingUser.companyId}, ${warehouseName}, ${warehouseCode}, ${fullAddress},
              ${city}, ${state}, 'India', TRUE, NOW(), NOW()
            )
          `);
        }
      });
      return { ...(await this.getStatus(firebaseUid)), complete: true };
    }

    const sameEmail = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id, "firebaseUid" FROM public.users WHERE lower(email) = ${email} LIMIT 1
    `);
    if (sameEmail.length) throw new Error("ACCOUNT_ALREADY_PROVISIONED");

    const companyId = randomUUID();
    const userId = randomUUID();
    const warehouseId = randomUUID();
    const companyCode = makeCode(companyName, "COMPANY");

    const codeConflict = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id FROM public.warehouses WHERE code = ${warehouseCodeBase} LIMIT 1
    `);
    const warehouseCode = codeConflict.length
      ? `${warehouseCodeBase.slice(0, 22)}-${randomUUID().slice(0, 6).toUpperCase()}`
      : warehouseCodeBase;

    await prisma.$transaction(async (tx) => {
      await tx.$executeRaw(Prisma.sql`
        INSERT INTO public.companies (id, name, code, "isActive", "createdAt", "updatedAt")
        VALUES (${companyId}, ${companyName}, ${companyCode}, TRUE, NOW(), NOW())
      `);
      await tx.$executeRaw(Prisma.sql`
        INSERT INTO public.users (id, "firebaseUid", email, name, role, "isActive", "companyId", "createdAt", "updatedAt")
        VALUES (${userId}, ${firebaseUid}, ${email}, ${name}, 'OWNER'::"UserRole", TRUE, ${companyId}, NOW(), NOW())
      `);
      await tx.$executeRaw(Prisma.sql`
        INSERT INTO public.warehouses (
          id, "companyId", name, code, address, city, state, country, "isActive", "createdAt", "updatedAt"
        ) VALUES (
          ${warehouseId}, ${companyId}, ${warehouseName}, ${warehouseCode}, ${fullAddress},
          ${city}, ${state}, 'India', TRUE, NOW(), NOW()
        )
      `);
    });

    return { ...(await this.getStatus(firebaseUid)), complete: true };
  }
}

export const onboardingService = new OnboardingService();
