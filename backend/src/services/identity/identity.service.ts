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
        c.status::text AS "companyStatus"
      FROM "User" u
      LEFT JOIN "Company" c ON c.id = u."companyId"
      WHERE u."firebaseUid" = ${firebaseUid}
      LIMIT 1
    `);

    if (!rows.length) {
      console.warn("[identity] no user for firebaseUid=", firebaseUid);
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
        w.status::text AS status,
        w."createdAt"
      FROM "Warehouse" w
      WHERE w."companyId" = ${row.companyId}
      ORDER BY w.name ASC
    `);

    const status = String(row.status ?? "").toLowerCase();
    const companyStatus = String(row.companyStatus ?? "").toLowerCase();

    return {
      id: row.id,
      firebaseUid: row.firebaseUid,
      email: row.email,
      name: row.name,
      phone: row.phone,
      role: row.role,
      isActive: status === "active",
      status: row.status,
      companyId: row.companyId,
      company: {
        id: row.companyId,
        name: row.companyName,
        code: null,
        isActive: companyStatus === "active",
        warehouses: (warehouses ?? []).map((w: any) => ({
          ...w,
          isActive: String(w.status ?? "").toLowerCase() === "active",
        })),
      },
    };
  }

  async getByFirebaseUid(firebaseUid: string) {
    const user = await this.getUserByFirebaseUid(firebaseUid);
    if (!user) throw new Error("USER_NOT_FOUND");
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
    console.warn("[identity] bootstrap email lookup=", email);

    const existingByEmail = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT id FROM "User" WHERE lower(email) = ${email} LIMIT 1
    `);

    if (existingByEmail.length) {
      await prisma.$executeRaw(Prisma.sql`
        UPDATE "User"
        SET "firebaseUid" = ${input.firebaseUid},
            "updatedAt" = NOW()
        WHERE id = ${existingByEmail[0].id}
      `);
      return this.getByFirebaseUid(input.firebaseUid);
    }

    throw new Error("USER_NOT_REGISTERED");
  }

  async updateProfile(firebaseUid: string, input: { name?: string }) {
    if (input.name !== undefined) {
      await prisma.$executeRaw(Prisma.sql`
        UPDATE "User"
        SET name = ${input.name.trim()},
            "updatedAt" = NOW()
        WHERE "firebaseUid" = ${firebaseUid}
      `);
    }
    return this.getUserByFirebaseUid(firebaseUid);
  }
}

export const identityService = new IdentityService();
