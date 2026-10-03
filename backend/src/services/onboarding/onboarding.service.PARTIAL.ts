import { Prisma } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

export class OnboardingService {
  async getStatus(firebaseUid: string) {
    const users = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT
        u.id,
        u."firebaseUid",
        u.email,
        u.name,
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

    if (!users.length) {
      return {
        exists: false,
        complete: false,
        user: null,
        company: null,
        warehouses: [],
      };
    }

    const u = users[0];
    const role = String(u.role ?? "").toLowerCase();

    // Platform owner: always complete — no seller onboarding
    if (role === "super_admin" || role === "platform_admin") {
      return {
        exists: true,
        complete: true,
        user: {
          id: u.id,
          firebaseUid: u.firebaseUid,
          email: u.email,
          name: u.name,
          role: u.role,
        },
        company: u.companyId
          ? { id: u.companyId, name: u.companyName, isActive: true }
          : null,
        warehouses: [],
      };
    }

    const warehouses = u.companyId
      ? await prisma.$queryRaw<any[]>(Prisma.sql`
          SELECT id, name, code, status::text AS status
          FROM "Warehouse"
          WHERE "companyId" = ${u.companyId}
          ORDER BY "createdAt" ASC
        `)
      : [];

    const complete =
      (u.name ?? "").toString().trim().length > 0 &&
      u.companyId != null &&
      warehouses.length > 0;

    return {
      exists: true,
      complete,
      user: {
        id: u.id,
        firebaseUid: u.firebaseUid,
        email: u.email,
        name: u.name,
        role: u.role,
      },
      company: u.companyId
        ? { id: u.companyId, name: u.companyName, isActive: true }
        : null,
      warehouses,
    };
  }
}

// Keep rest of file - if full replace breaks other methods, only patch getStatus manually
export const onboardingService = new OnboardingService();
