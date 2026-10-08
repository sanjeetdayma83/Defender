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
  const source = clean(value);

  const generated = source
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 30);

  return generated || fallback;
}

function asAddress(
  address: string,
  city: string,
  state: string,
  pin: string,
) {
  return {
    line1: address,
    city,
    state,
    postalCode: pin,
    country: "India",
  };
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
        u.phone,
        u.role::text AS role,
        u.status::text AS status,
        c."companyName" AS "companyName",
        c.email AS "companyEmail",
        c.phone AS "companyPhone",
        c.address AS "companyAddress",
        c.status::text AS "companyStatus",
        c.plan::text AS plan
      FROM "User" u
      JOIN "Company" c
        ON c.id = u."companyId"
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
        w.timezone,
        w.status::text AS status,
        w."createdAt"
      FROM "Warehouse" w
      WHERE w."companyId" = ${companyId}
      ORDER BY w."createdAt" ASC, w.name ASC
    `);
  }

  async getStatus(firebaseUid: string) {
    const user = await this.findUser(firebaseUid);

    if (!user) {
      return {
        exists: false,
        complete: false,
        user: null,
        company: null,
        warehouses: [],
      };
    }

    const warehouses = await this.getWarehouses(user.companyId);

    const complete =
      clean(user.name).length > 0 &&
      clean(user.companyName).length > 0 &&
      warehouses.length > 0;

    return {
      exists: true,
      complete,
      user: {
        id: user.id,
        firebaseUid: user.firebaseUid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        status: user.status,
      },
      company: {
        id: user.companyId,
        name: user.companyName,
        code: "",
        email: user.companyEmail,
        phone: user.companyPhone,
        address: user.companyAddress,
        plan: user.plan,
        isActive: String(user.companyStatus).toLowerCase() === "active",
      },
      warehouses: warehouses.map((w: any) => ({
        ...w,
        isActive: String(w.status ?? "").toLowerCase() === "active",
      })),
    };
  }

  async updateProfile(firebaseUid: string, input: { name?: unknown }) {
    const user = await this.findUser(firebaseUid);

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    const name = clean(input.name);

    if (!name) {
      throw new Error("NAME_REQUIRED");
    }

    await prisma.$executeRaw(Prisma.sql`
      UPDATE "User"
      SET
        name = ${name},
        "updatedAt" = NOW()
      WHERE id = ${user.id}
    `);

    return this.getStatus(firebaseUid);
  }

  async updateCompany(
    firebaseUid: string,
    input: {
      name?: unknown;
      phone?: unknown;
      address?: unknown;
      city?: unknown;
      state?: unknown;
      pin?: unknown;
    },
  ) {
    const user = await this.findUser(firebaseUid);

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    const name = clean(input.name);
    const phone = clean(input.phone) || clean(user.companyPhone);

    if (!name) {
      throw new Error("COMPANY_NAME_REQUIRED");
    }

    if (!phone) {
      throw new Error("PHONE_REQUIRED");
    }

    const address = clean(input.address);
    const city = clean(input.city);
    const state = clean(input.state);
    const pin = clean(input.pin);

    const addressJson = JSON.stringify(
      asAddress(address, city, state, pin),
    );

    await prisma.$executeRaw(Prisma.sql`
      UPDATE "Company"
      SET
        "companyName" = ${name},
        phone = ${phone},
        address = ${addressJson}::jsonb,
        "updatedAt" = NOW()
      WHERE id = ${user.companyId}
    `);

    return this.getStatus(firebaseUid);
  }

  async createWarehouse(
    firebaseUid: string,
    input: {
      name?: unknown;
      code?: unknown;
      address?: unknown;
      city?: unknown;
      state?: unknown;
    },
  ) {
    const user = await this.findUser(firebaseUid);

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    const name = clean(input.name);

    if (!name) {
      throw new Error("WAREHOUSE_NAME_REQUIRED");
    }

    let code = makeCode(clean(input.code), makeCode(name, "WAREHOUSE"));

    const existing = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id
      FROM "Warehouse"
      WHERE "companyId" = ${user.companyId}
        AND code = ${code}
      LIMIT 1
    `);

    if (existing.length) {
      const sameName = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT id
        FROM "Warehouse"
        WHERE id = ${existing[0].id}
          AND lower(name) = lower(${name})
        LIMIT 1
      `);

      if (!sameName.length) {
        throw new Error("WAREHOUSE_CODE_EXISTS");
      }

      return existing[0];
    }

    const id = randomUUID();

    const address = JSON.stringify({
      line1: clean(input.address),
      city: clean(input.city),
      state: clean(input.state),
      country: "India",
    });

    await prisma.$executeRaw(Prisma.sql`
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
        ${id},
        ${user.companyId},
        ${name},
        ${code},
        ${address}::jsonb,
        ${clean(input.city)},
        ${clean(input.state)},
        'India',
        'Asia/Kolkata',
        'active'::"Status",
        NOW()
      )
    `);

    return { id, name, code };
  }

  async complete(firebaseUid: string, input: SetupInput) {
    const name = clean(input.name);
    const email = clean(input.email).toLowerCase();
    const phone = clean(input.phone);
    const companyName = clean(input.companyName);
    const address = clean(input.address);
    const city = clean(input.city);
    const state = clean(input.state);
    const pin = clean(input.pin);
    const warehouseName = clean(input.warehouseName);
    const requestedWarehouseCode = clean(input.warehouseCode);

    if (!name) {
      throw new Error("NAME_REQUIRED");
    }

    if (!email) {
      throw new Error("EMAIL_REQUIRED");
    }

    if (!phone) {
      throw new Error("PHONE_REQUIRED");
    }

    if (!companyName) {
      throw new Error("COMPANY_NAME_REQUIRED");
    }

    if (!address) {
      throw new Error("ADDRESS_REQUIRED");
    }

    if (!city) {
      throw new Error("CITY_REQUIRED");
    }

    if (!state) {
      throw new Error("STATE_REQUIRED");
    }

    if (!pin) {
      throw new Error("PIN_REQUIRED");
    }

    if (!warehouseName) {
      throw new Error("WAREHOUSE_NAME_REQUIRED");
    }

    const existingUser = await this.findUser(firebaseUid);

    if (existingUser) {
      const companyId = existingUser.companyId;
      let warehouseCode = makeCode(
        requestedWarehouseCode,
        makeCode(warehouseName, "WAREHOUSE"),
      );

      const codeConflict = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT id, name
        FROM "Warehouse"
        WHERE "companyId" = ${companyId}
          AND code = ${warehouseCode}
        LIMIT 1
      `);

      if (
        codeConflict.length &&
        clean(codeConflict[0].name).toLowerCase() !==
          warehouseName.toLowerCase()
      ) {
        throw new Error("WAREHOUSE_CODE_EXISTS");
      }

      const existingWarehouse = await prisma.$queryRaw<any[]>(Prisma.sql`
        SELECT id
        FROM "Warehouse"
        WHERE "companyId" = ${companyId}
        ORDER BY "createdAt" ASC
        LIMIT 1
      `);

      const addressJson = JSON.stringify(
        asAddress(address, city, state, pin),
      );

      await prisma.$transaction(async (tx) => {
        await tx.$executeRaw(Prisma.sql`
          UPDATE "User"
          SET
            name = ${name},
            phone = ${phone},
            "status" = 'active'::"UserStatus",
            "updatedAt" = NOW()
          WHERE id = ${existingUser.id}
        `);

        await tx.$executeRaw(Prisma.sql`
          UPDATE "Company"
          SET
            "companyName" = ${companyName},
            phone = ${phone},
            address = ${addressJson}::jsonb,
            "updatedAt" = NOW()
          WHERE id = ${companyId}
        `);

        if (existingWarehouse.length) {
          await tx.$executeRaw(Prisma.sql`
            UPDATE "Warehouse"
            SET
              name = ${warehouseName},
              code = ${warehouseCode},
              address = ${addressJson}::jsonb,
              city = ${city},
              state = ${state},
              country = 'India',
              timezone = 'Asia/Kolkata',
              status = 'active'::"Status"
            WHERE id = ${existingWarehouse[0].id}
          `);
        } else {
          await tx.$executeRaw(Prisma.sql`
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
              ${randomUUID()},
              ${companyId},
              ${warehouseName},
              ${warehouseCode},
              ${addressJson}::jsonb,
              ${city},
              ${state},
              'India',
              'Asia/Kolkata',
              'active'::"Status",
              NOW()
            )
          `);
        }
      });

      return { ...(await this.getStatus(firebaseUid)), complete: true };
    }

    const sameEmail = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        id,
        "firebaseUid",
        "companyId",
        role::text AS role,
        status::text AS status
      FROM "User"
      WHERE lower(email) = ${email}
      LIMIT 1
    `);

    if (sameEmail.length) {
      throw new Error("ACCOUNT_ALREADY_PROVISIONED");
    }

    const companyId = randomUUID();
    const userId = randomUUID();
    const warehouseId = randomUUID();

    let warehouseCode = makeCode(
      requestedWarehouseCode,
      makeCode(warehouseName, "WAREHOUSE"),
    );

    const codeConflict = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id
      FROM "Warehouse"
      WHERE code = ${warehouseCode}
      LIMIT 1
    `);

    if (codeConflict.length) {
      warehouseCode = `${warehouseCode.slice(0, 22)}-${Math.random()
        .toString(36)
        .slice(2, 8)
        .toUpperCase()}`;
    }

    const addressJson = JSON.stringify(
      asAddress(address, city, state, pin),
    );

    await prisma.$transaction(async (tx) => {
      await tx.$executeRaw(Prisma.sql`
        INSERT INTO "Company" (
          id,
          "companyName",
          email,
          phone,
          address,
          timezone,
          currency,
          plan,
          "storageUsed",
          "storageQuota",
          status,
          "createdAt",
          "updatedAt"
        )
        VALUES (
          ${companyId},
          ${companyName},
          ${email},
          ${phone},
          ${addressJson}::jsonb,
          'Asia/Kolkata',
          'INR',
          'free'::"Plan",
          0,
          5368709120,
          'active'::"Status",
          NOW(),
          NOW()
        )
      `);

      await tx.$executeRaw(Prisma.sql`
        INSERT INTO "User" (
          id,
          "firebaseUid",
          "companyId",
          name,
          email,
          phone,
          role,
          status,
          "createdAt",
          "updatedAt"
        )
        VALUES (
          ${userId},
          ${firebaseUid},
          ${companyId},
          ${name},
          ${email},
          ${phone},
          'company_admin'::"Role",
          'active'::"UserStatus",
          NOW(),
          NOW()
        )
      `);

      await tx.$executeRaw(Prisma.sql`
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
          ${warehouseName},
          ${warehouseCode},
          ${addressJson}::jsonb,
          ${city},
          ${state},
          'India',
          'Asia/Kolkata',
          'active'::"Status",
          NOW()
        )
      `);
    });

    return { ...(await this.getStatus(firebaseUid)), complete: true };
  }
}

export const onboardingService = new OnboardingService();
