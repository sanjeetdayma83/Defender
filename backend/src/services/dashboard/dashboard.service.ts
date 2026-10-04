import { prisma } from "../../config/prisma.js";

async function rawCount(label: string, sql: string): Promise<number> {
  try {
    const rows = await prisma.$queryRawUnsafe<any[]>(sql);
    return Number(rows?.[0]?.c ?? 0) || 0;
  } catch (e) {
    console.warn(`[dashboard] ${label}`, e);
    return 0;
  }
}

export class DashboardService {
  async companyMetrics(companyId: string) {
    return {
      orders: await rawCount("o", `SELECT COUNT(*)::int AS c FROM "Order" WHERE "companyId"='${companyId}'`),
      products: 0, warehouses: 0, users: 0, sessions: 0, evidence: 0,
    };
  }
  async platformMetrics() {
    return {
      companies: await rawCount("Company", `SELECT COUNT(*)::int AS c FROM "Company"`),
      users: await rawCount("User", `SELECT COUNT(*)::int AS c FROM "User"`),
      warehouses: await rawCount("Warehouse", `SELECT COUNT(*)::int AS c FROM "Warehouse"`),
      orders: await rawCount("Order", `SELECT COUNT(*)::int AS c FROM "Order"`),
      sessions: await rawCount("PackingSession", `SELECT COUNT(*)::int AS c FROM "PackingSession"`),
      evidence: await rawCount("EvidenceMedia", `SELECT COUNT(*)::int AS c FROM "EvidenceMedia"`),
    };
  }
}
export const dashboardService = new DashboardService();
