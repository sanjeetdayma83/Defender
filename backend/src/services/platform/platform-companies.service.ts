import { prisma } from "../../config/prisma.js";

export type PlatformCompanyRow = {
  id: string;
  name: string;
  code: string | null;
  status: string;
  userCount: number;
  warehouseCount: number;
  planName: string | null;
  subscriptionStatus: string | null;
  createdAt: string;
};

export class PlatformCompaniesService {
  async list(opts: {
    search?: string;
    status?: "all" | "active" | "inactive";
    limit?: number;
  }): Promise<{ total: number; items: PlatformCompanyRow[] }> {
    const limit = Math.min(Math.max(opts.limit ?? 50, 1), 200);
    const search = (opts.search ?? "").trim();
    const status = opts.status ?? "all";

    let rows: any[] = [];
    try {
      rows = await prisma.$queryRawUnsafe<any[]>(
        `SELECT c.id, c."companyName" AS name, c.status::text AS status, c."createdAt",
          (SELECT COUNT(*)::int FROM "User" u WHERE u."companyId" = c.id) AS "userCount",
          (SELECT COUNT(*)::int FROM "Warehouse" w WHERE w."companyId" = c.id) AS "warehouseCount"
         FROM "Company" c ORDER BY c."createdAt" DESC NULLS LAST LIMIT $1`,
        limit,
      );
    } catch (e) {
      console.warn("[companies] path1", e);
      rows = await prisma.$queryRawUnsafe<any[]>(
        `SELECT c.id, COALESCE(c."companyName", 'Company') AS name,
          COALESCE(c.status::text, 'active') AS status, c."createdAt",
          0 AS "userCount", 0 AS "warehouseCount"
         FROM "Company" c ORDER BY c."createdAt" DESC NULLS LAST LIMIT $1`,
        limit,
      );
    }

    let items: PlatformCompanyRow[] = (rows ?? []).map((r) => ({
      id: String(r.id),
      name: String(r.name ?? "Company"),
      code: null,
      status: String(r.status ?? "active").toUpperCase(),
      userCount: Number(r.userCount ?? 0),
      warehouseCount: Number(r.warehouseCount ?? 0),
      planName: null,
      subscriptionStatus: null,
      createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
    }));

    if (status === "active") items = items.filter((i) => i.status === "ACTIVE");
    else if (status === "inactive") items = items.filter((i) => i.status !== "ACTIVE");
    if (search) {
      const q = search.toLowerCase();
      items = items.filter((i) => i.name.toLowerCase().includes(q));
    }
    return { total: items.length, items };
  }

  async setActive(companyId: string, isActive: boolean) {
    const st = isActive ? "active" : "suspended";
    try {
      await prisma.$executeRawUnsafe(
        `UPDATE "Company" SET status = $1, "updatedAt" = NOW() WHERE id = $2`,
        st, companyId,
      );
    } catch {
      await prisma.$executeRawUnsafe(
        `UPDATE "Company" SET "isActive" = $1, "updatedAt" = NOW() WHERE id = $2`,
        isActive, companyId,
      );
    }
    return { id: companyId, isActive, status: st.toUpperCase() };
  }
}
