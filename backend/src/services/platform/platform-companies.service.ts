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

    try {
      return await this.listViaPrisma(search, opts.status ?? "all", limit);
    } catch (e) {
      console.warn("[platform/companies] prisma path failed, trying raw:", e);
      return await this.listViaRaw(search, opts.status ?? "all", limit);
    }
  }

  async setActive(companyId: string, isActive: boolean) {
    try {
      const updated = await prisma.company.update({
        where: { id: companyId },
        data: { isActive },
      });
      return {
        id: updated.id,
        name: updated.name,
        isActive: updated.isActive,
      };
    } catch (e) {
      console.warn("[platform/companies] prisma update failed, raw:", e);
      await prisma.$executeRawUnsafe(
        `UPDATE "Company" SET status = $1, "updatedAt" = NOW() WHERE id = $2`,
        isActive ? "active" : "suspended",
        companyId,
      );
      return { id: companyId, isActive };
    }
  }

  private async listViaPrisma(
    search: string,
    status: string,
    limit: number,
  ): Promise<{ total: number; items: PlatformCompanyRow[] }> {
    const where: any = {};
    if (status === "active") where.isActive = true;
    if (status === "inactive") where.isActive = false;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { code: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, rows] = await Promise.all([
      prisma.company.count({ where }),
      prisma.company.findMany({
        where,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          _count: { select: { users: true, warehouses: true } },
          subscription: { include: { plan: true } },
        },
      }),
    ]);

    const items: PlatformCompanyRow[] = rows.map((c) => ({
      id: c.id,
      name: c.name,
      code: c.code,
      status: c.isActive ? "ACTIVE" : "INACTIVE",
      userCount: c._count.users,
      warehouseCount: c._count.warehouses,
      planName: c.subscription?.plan?.name ?? null,
      subscriptionStatus: c.subscription?.status ?? null,
      createdAt: c.createdAt.toISOString(),
    }));

    return { total, items };
  }

  private async listViaRaw(
    search: string,
    status: string,
    limit: number,
  ): Promise<{ total: number; items: PlatformCompanyRow[] }> {
    // Legacy-friendly: "Company" with companyName / status
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        c.id,
        COALESCE(c."companyName", c.name) AS name,
        COALESCE(c.code, '') AS code,
        COALESCE(c.status::text, CASE WHEN c."isActive" THEN 'active' ELSE 'inactive' END) AS status,
        c."createdAt",
        (SELECT COUNT(*)::int FROM "User" u WHERE u."companyId" = c.id) AS "userCount",
        (SELECT COUNT(*)::int FROM "Warehouse" w WHERE w."companyId" = c.id) AS "warehouseCount"
      FROM "Company" c
      ORDER BY c."createdAt" DESC NULLS LAST
      LIMIT $1
      `,
      limit,
    );

    let items: PlatformCompanyRow[] = (rows ?? []).map((r) => ({
      id: String(r.id),
      name: String(r.name ?? "Company"),
      code: r.code ? String(r.code) : null,
      status: String(r.status ?? "active").toUpperCase(),
      userCount: Number(r.userCount ?? 0),
      warehouseCount: Number(r.warehouseCount ?? 0),
      planName: null,
      subscriptionStatus: null,
      createdAt: r.createdAt
        ? new Date(r.createdAt).toISOString()
        : new Date().toISOString(),
    }));

    if (status === "active") {
      items = items.filter((i) =>
        ["ACTIVE", "active"].includes(i.status),
      );
    } else if (status === "inactive") {
      items = items.filter(
        (i) => !["ACTIVE", "active"].includes(i.status),
      );
    }
    if (search) {
      const q = search.toLowerCase();
      items = items.filter(
        (i) =>
          i.name.toLowerCase().includes(q) ||
          (i.code ?? "").toLowerCase().includes(q),
      );
    }

    return { total: items.length, items };
  }
}
