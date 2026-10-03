import { prisma } from "../../config/prisma.js";

async function safeCount(
  label: string,
  fn: () => Promise<number>,
): Promise<number> {
  try {
    return await fn();
  } catch (e) {
    console.warn(`[dashboard] ${label} count failed:`, e);
    return 0;
  }
}

async function rawCount(label: string, sql: string): Promise<number> {
  try {
    const rows = await prisma.$queryRawUnsafe<Array<{ c: bigint | number }>>(sql);
    const v = rows?.[0]?.c;
    return typeof v === "bigint" ? Number(v) : Number(v ?? 0);
  } catch (e) {
    console.warn(`[dashboard] ${label} raw count failed:`, e);
    return 0;
  }
}

export class DashboardService {
  async companyMetrics(companyId: string) {
    const [orders, products, warehouses, users, sessions, evidence] =
      await Promise.all([
        safeCount("order", () => prisma.order.count({ where: { companyId } })),
        safeCount("product", () =>
          prisma.product.count({ where: { companyId } }),
        ),
        safeCount("warehouse", () =>
          prisma.warehouse.count({ where: { companyId } }),
        ),
        safeCount("user", () =>
          prisma.user.count({ where: { companyId } }),
        ),
        safeCount("packingSession", () =>
          prisma.packingSession.count({
            where: { warehouse: { companyId } },
          }),
        ),
        safeCount("evidenceMedia", () =>
          prisma.evidenceMedia.count({
            where: { packingSession: { warehouse: { companyId } } },
          }),
        ),
      ]);

    const [pendingOrders, packingOrders, packedOrders, activeSessions] =
      await Promise.all([
        safeCount("order.pending", () =>
          prisma.order.count({ where: { companyId, status: "PENDING" } }),
        ),
        safeCount("order.packing", () =>
          prisma.order.count({ where: { companyId, status: "PACKING" } }),
        ),
        safeCount("order.packed", () =>
          prisma.order.count({ where: { companyId, status: "PACKED" } }),
        ),
        safeCount("session.active", () =>
          prisma.packingSession.count({
            where: { status: "ACTIVE", warehouse: { companyId } },
          }),
        ),
      ]);

    return {
      companyId,
      counts: { orders, products, warehouses, users, sessions, evidence },
      orderStatus: {
        pending: pendingOrders,
        packing: packingOrders,
        packed: packedOrders,
      },
      activeSessions,
    };
  }

  /** Never throws — missing models/tables return 0. */
  async platformMetrics() {
    const companies = await safeCount("company", () => prisma.company.count());
    const users = await safeCount("user", () => prisma.user.count());
    const warehouses = await safeCount("warehouse", () =>
      prisma.warehouse.count(),
    );

    // Orders / sessions / evidence often missing or renamed on legacy DB
    let orders = await safeCount("order", () => prisma.order.count());
    if (orders === 0) {
      orders = await rawCount(
        "Order",
        `SELECT COUNT(*)::bigint AS c FROM "Order"`,
      );
    }

    let sessions = await safeCount("packingSession", () =>
      prisma.packingSession.count(),
    );
    if (sessions === 0) {
      sessions = await rawCount(
        "PackingSession",
        `SELECT COUNT(*)::bigint AS c FROM "PackingSession"`,
      );
    }

    let evidence = await safeCount("evidenceMedia", () =>
      prisma.evidenceMedia.count(),
    );
    if (evidence === 0) {
      evidence = await rawCount(
        "EvidenceMedia",
        `SELECT COUNT(*)::bigint AS c FROM "EvidenceMedia"`,
      );
    }

    return {
      companies,
      users,
      orders,
      sessions,
      evidence,
      warehouses,
    };
  }
}
