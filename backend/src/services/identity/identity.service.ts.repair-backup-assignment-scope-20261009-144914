import { Prisma } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

export class IdentityService {
  private async getUserByFirebaseUid(firebaseUid: string) {
    // Compatibility with the existing lowercase legacy tables.
    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        u.id,
        u."firebaseUid",
        u.email,
        u.name,
        NULL::text AS phone,
        u.role::text AS role,
        CASE WHEN u."isActive" THEN 'ACTIVE' ELSE 'INACTIVE' END AS status,
        u."companyId",
        c.name AS "companyName",
        c.code AS "companyCode",
        c."isActive" AS "companyIsActive"
      FROM public.users u
      LEFT JOIN public.companies c
        ON c.id = u."companyId"
      WHERE u."firebaseUid" = ${firebaseUid}
      LIMIT 1
    `);

    if (!rows.length) return null;

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
        CASE WHEN w."isActive" THEN 'ACTIVE' ELSE 'INACTIVE' END AS status,
        w."createdAt"
      FROM public.warehouses w
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
      status: row.status,
      isActive: Boolean(row.isActive ?? row.status === "ACTIVE"),
      companyId: row.companyId,
      company: {
        id: row.companyId,
        name: row.companyName,
        code: row.companyCode ?? "",
        email: null,
        phone: null,
        isActive: Boolean(row.companyIsActive),
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
        timezone: null,
        status: w.status,
        isActive: w.status === "ACTIVE",
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
    if (existing) return existing;

    const email = input.email.trim().toLowerCase();

    const existingByEmail = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id, "firebaseUid"
      FROM public.users
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
      UPDATE public.users
      SET "firebaseUid" = ${input.firebaseUid},
          "updatedAt" = NOW()
      WHERE id = ${existingByEmail[0].id}
    `);

    return this.getByFirebaseUid(input.firebaseUid);
  }

  async updateProfile(firebaseUid: string, input: { name?: string }) {
    const name = input.name?.trim();

    if (name) {
      await prisma.$executeRaw(Prisma.sql`
        UPDATE public.users
        SET name = ${name}, "updatedAt" = NOW()
        WHERE "firebaseUid" = ${firebaseUid}
      `);
    }

    return this.getByFirebaseUid(firebaseUid);
  }
}

export const identityService = new IdentityService();
