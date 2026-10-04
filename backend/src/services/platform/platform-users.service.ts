import { Prisma } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

export type PlatformUserRow = {
  id: string; email: string; name: string | null; role: string;
  status: string; companyId: string | null; companyName: string | null; createdAt: string;
};

export class PlatformUsersService {
  async list(opts: { search?: string; status?: "all" | "active" | "inactive"; role?: string; limit?: number; }) {
    const limit = Math.min(Math.max(opts.limit ?? 100, 1), 200);
    const rows = await prisma.$queryRaw<any[]>(Prisma.sql`
      SELECT u.id, u.email, u.name, u.role::text AS role, u.status::text AS status,
        u."companyId", c."companyName" AS "companyName", u."createdAt"
      FROM "User" u LEFT JOIN "Company" c ON c.id = u."companyId"
      ORDER BY u."createdAt" DESC NULLS LAST LIMIT ${limit}
    `);
    let items: PlatformUserRow[] = (rows ?? []).map((r) => ({
      id: String(r.id), email: String(r.email ?? ""), name: r.name != null ? String(r.name) : null,
      role: String(r.role ?? "OPERATOR"), status: String(r.status ?? "active").toUpperCase(),
      companyId: r.companyId != null ? String(r.companyId) : null,
      companyName: r.companyName != null ? String(r.companyName) : null,
      createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
    }));
    if (opts.status === "active") items = items.filter((i) => i.status === "ACTIVE");
    else if (opts.status === "inactive") items = items.filter((i) => i.status !== "ACTIVE");
    if (opts.role?.trim()) {
      const rf = opts.role.trim().toUpperCase().replace(/-/g, "_");
      items = items.filter((i) => i.role.toUpperCase().replace(/-/g, "_") === rf);
    }
    if (opts.search?.trim()) {
      const q = opts.search.trim().toLowerCase();
      items = items.filter((i) =>
        i.email.toLowerCase().includes(q) || (i.name ?? "").toLowerCase().includes(q) ||
        (i.companyName ?? "").toLowerCase().includes(q));
    }
    return { total: items.length, items };
  }

  async setStatus(userId: string, active: boolean) {
    const status = active ? "active" : "suspended";
    try {
      await prisma.$executeRaw(Prisma.sql`
        UPDATE "User" SET status = ${status}::"UserStatus", "updatedAt" = NOW() WHERE id = ${userId}`);
    } catch {
      await prisma.$executeRaw(Prisma.sql`
        UPDATE "User" SET status = ${status}, "updatedAt" = NOW() WHERE id = ${userId}`);
    }
    return { id: userId, status: status.toUpperCase() };
  }
}
