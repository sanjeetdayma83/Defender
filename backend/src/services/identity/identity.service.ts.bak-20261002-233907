import { prisma } from "../../config/prisma.js";

export type LiveRole =
  | "PLATFORM_ADMIN"
  | "OWNER"
  | "ADMIN"
  | "MANAGER"
  | "OPERATOR"
  | "VIEWER"
  | "company_admin"
  | "warehouse_manager"
  | "operator"
  | "viewer";

export class IdentityService {
  private async getLegacyUser(firebaseUid: string) {
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        u.id,
        u."clerkId" AS "firebaseUid",
        u.email,
        u.name,
        u.phone,
        u.role,
        u.status,
        u."companyId",
        c."companyName" AS "companyName",
        c.status AS "companyStatus"
       FROM "User" u
       LEFT JOIN "Company" c ON c.id = u."companyId"
       WHERE u."clerkId" = $1
       LIMIT 1`,
      firebaseUid,
    );

    if (!rows.length) return null;

    const row = rows[0];

    const warehouses = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        w.id,
        w."companyId",
        w.name,
        w.code,
        w.address,
        w.city,
        w.state,
        w.country,
        w.timezone,
        w.status,
        w."createdAt"
       FROM "Warehouse" w
       WHERE w."companyId" = $1
       ORDER BY w.name ASC`,
      row.companyId,
    );

    return {
      id: row.id,
      firebaseUid: row.firebaseUid,
      email: row.email,
      name: row.name,
      phone: row.phone,
      role: row.role,
      isActive: String(row.status).toLowerCase() === "active",
      status: row.status,
      companyId: row.companyId,
      company: {
        id: row.companyId,
        name: row.companyName,
        code: null,
        isActive: String(row.companyStatus).toLowerCase() === "active",
        warehouses,
      },
    };
  }

  async getByFirebaseUid(firebaseUid: string) {
    const user = await this.getLegacyUser(firebaseUid);

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
    const existing = await this.getLegacyUser(input.firebaseUid);

    if (existing) {
      return existing;
    }

    const email = input.email.trim().toLowerCase();

    const existingByEmail = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        u.id,
        u."clerkId" AS "firebaseUid",
        u.email,
        u.name,
        u.phone,
        u.role,
        u.status,
        u."companyId",
        c."companyName" AS "companyName",
        c.status AS "companyStatus"
       FROM "User" u
       LEFT JOIN "Company" c ON c.id = u."companyId"
       WHERE lower(u.email) = lower($1)
       LIMIT 1`,
      email,
    );

    if (existingByEmail.length) {
      const existingUser = existingByEmail[0];

      await prisma.$executeRawUnsafe(
        `UPDATE "User"
         SET "clerkId" = $1,
             "updatedAt" = NOW()
         WHERE id = $2`,
        input.firebaseUid,
        existingUser.id,
      );

      const linkedUser = await this.getLegacyUser(input.firebaseUid);

      if (!linkedUser) {
        throw new Error("USER_NOT_FOUND");
      }

      return linkedUser;
    }

    throw new Error("USER_NOT_REGISTERED");
  }

  async updateProfile(
    firebaseUid: string,
    input: {
      name?: string;
    },
  ) {
    if (input.name !== undefined) {
      await prisma.$executeRawUnsafe(
        `UPDATE "User"
         SET name = $1,
             "updatedAt" = NOW()
         WHERE "clerkId" = $2`,
        input.name.trim(),
        firebaseUid,
      );
    }

    return this.getLegacyUser(firebaseUid);
  }
}

export const identityService = new IdentityService();
