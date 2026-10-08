import { Prisma } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

export class IdentityService {
  private async getUserByFirebaseUid(firebaseUid: string) {
    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        u.id,
        u."firebaseUid",
        u.email,
        u.name,
        u.phone,
        u.role::text AS role,
        u.status::text AS status,
        u."companyId",
        c."companyName" AS "companyName",
        c.email AS "companyEmail",
        c.phone AS "companyPhone",
        c.status::text AS "companyStatus"
      FROM "User" u
      LEFT JOIN "Company" c
        ON c.id = u."companyId"
      WHERE u."firebaseUid" = ${firebaseUid}
      LIMIT 1
    `);

    if (!rows.length) {
      return null;
    }

    const row = rows[0];

    const warehouses = await prisma.$queryRaw<any[]>(Prisma.sql`
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
      WHERE w."companyId" = ${row.companyId}
      ORDER BY w."createdAt" ASC, w.name ASC
    `);

    return {
      id: row.id,
      firebaseUid: row.firebaseUid,
      email: row.email,
      name: row.name,
      phone: row.phone,
      role: row.role,
      isActive: String(row.status ?? "").toLowerCase() === "active",
      status: row.status,
      companyId: row.companyId,
      company: {
        id: row.companyId,
        name: row.companyName,
        code: "",
        email: row.companyEmail,
        phone: row.companyPhone,
        isActive:
          String(row.companyStatus ?? "").toLowerCase() === "active",
      },
      warehouses: (warehouses ?? []).map((w: any) => ({
        id: w.id,
        companyId: w.companyId,
        name: w.name,
        code: w.code,
        address: w.address,
        city: w.city,
        state: w.state,
        country: w.country,
        timezone: w.timezone,
        status: w.status,
        isActive: String(w.status ?? "").toLowerCase() === "active",
      })),
    };
  }

  async getByFirebaseUid(firebaseUid: string) {
    const user = await this.getUserByFirebaseUid(firebaseUid);

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    return user;
  }

  async bootstrapUser(input: {
    firebaseUid: string;
    email: string;
    name?: string;
  }) {
    const existing = await this.getUserByFirebaseUid(input.firebaseUid);

    if (existing) {
      return existing;
    }

    const email = input.email.trim().toLowerCase();

    const existingByEmail = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        id,
        "firebaseUid"
      FROM "User"
      WHERE lower(email) = ${email}
      LIMIT 1
    `);

    if (!existingByEmail.length) {
      throw new Error("USER_NOT_REGISTERED");
    }

    const existingUid = existingByEmail[0].firebaseUid;

    if (existingUid && existingUid !== input.firebaseUid) {
      throw new Error("ACCOUNT_ALREADY_LINKED");
    }

    await prisma.$executeRaw(Prisma.sql`
      UPDATE "User"
      SET
        "firebaseUid" = ${input.firebaseUid},
        "updatedAt" = NOW()
      WHERE id = ${existingByEmail[0].id}
    `);

    return this.getByFirebaseUid(input.firebaseUid);
  }

  async updateProfile(firebaseUid: string, input: { name?: string }) {
    const name = input.name?.trim();

    if (name) {
      await prisma.$executeRaw(Prisma.sql`
        UPDATE "User"
        SET
          name = ${name},
          "updatedAt" = NOW()
        WHERE "firebaseUid" = ${firebaseUid}
      `);
    }

    return this.getByFirebaseUid(firebaseUid);
  }
}

export const identityService = new IdentityService();
