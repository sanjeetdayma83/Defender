import { prisma } from "../../config/prisma.js";

export class CompanyContextService {
  async getUser(firebaseUid: string) {
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        u.id,
        u."firebaseUid" AS "firebaseUid",
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
       WHERE u."firebaseUid" = $1
       LIMIT 1`,
      firebaseUid,
    );

    if (!rows.length) {
      throw new Error("USER_NOT_FOUND");
    }

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
      status: row.status,
      isActive: String(row.status).toLowerCase() === "active",
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

  async getCompany(firebaseUid: string) {
    const user = await this.getUser(firebaseUid);
    return {
      user,
      company: user.company,
    };
  }
}

export const companyContextService = new CompanyContextService();


