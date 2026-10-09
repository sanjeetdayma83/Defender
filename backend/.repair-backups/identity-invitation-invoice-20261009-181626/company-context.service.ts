import { prisma } from "../../config/prisma.js";

export class CompanyContextService {
  async getUser(firebaseUid: string) {
    // Use the verified legacy production schema.
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        u.id,
        u."firebaseUid",
        u.email,
        u.name,
        u.role::text AS role,
        u."isActive" AS "userIsActive",
        u."companyId",
        c.name AS "companyName",
        c.code AS "companyCode",
        c."isActive" AS "companyIsActive"
       FROM public.users u
       INNER JOIN public.companies c ON c.id = u."companyId"
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
        w."isActive" AS "isActive",
        w."createdAt"
       FROM public.warehouses w
       WHERE w."companyId" = $1
       ORDER BY w.name ASC`,
      row.companyId,
    );

    const normalizedWarehouses = warehouses.map((warehouse: any) => ({
      ...warehouse,
      timezone: null,
      status: warehouse.isActive ? "active" : "suspended",
      isActive: Boolean(warehouse.isActive),
    }));

    return {
      id: row.id,
      firebaseUid: row.firebaseUid,
      email: row.email,
      name: row.name,
      phone: null,
      role: row.role,
      status: row.userIsActive ? "active" : "suspended",
      isActive: Boolean(row.userIsActive),
      companyId: row.companyId,
      company: {
        id: row.companyId,
        name: row.companyName,
        code: row.companyCode,
        isActive: Boolean(row.companyIsActive),
        warehouses: normalizedWarehouses,
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
