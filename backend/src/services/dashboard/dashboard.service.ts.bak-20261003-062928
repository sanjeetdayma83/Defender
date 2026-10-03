import { prisma } from "../../config/prisma.js";

export class DashboardService {
  async companyMetrics(companyId: string) {
    const [orders, products, warehouses, users, sessions, evidence] =
      await Promise.all([
        prisma.order.count({
          where: {
            companyId,
          },
        }),

        prisma.product.count({
          where: {
            companyId,
          },
        }),

        prisma.warehouse.count({
          where: {
            companyId,
            isActive: true,
          },
        }),

        prisma.user.count({
          where: {
            companyId,
            isActive: true,
          },
        }),

        prisma.packingSession.count({
          where: {
            warehouse: {
              companyId,
            },
          },
        }),

        prisma.evidenceMedia.count({
          where: {
            packingSession: {
              warehouse: {
                companyId,
              },
            },
          },
        }),
      ]);

    const [pendingOrders, packingOrders, packedOrders, activeSessions] =
      await Promise.all([
        prisma.order.count({
          where: {
            companyId,
            status: "PENDING",
          },
        }),

        prisma.order.count({
          where: {
            companyId,
            status: "PACKING",
          },
        }),

        prisma.order.count({
          where: {
            companyId,
            status: "PACKED",
          },
        }),

        prisma.packingSession.count({
          where: {
            status: "ACTIVE",
            warehouse: {
              companyId,
            },
          },
        }),
      ]);

    return {
      companyId,
      counts: {
        orders,
        products,
        warehouses,
        users,
        sessions,
        evidence,
      },
      orderStatus: {
        pending: pendingOrders,
        packing: packingOrders,
        packed: packedOrders,
      },
      activeSessions,
    };
  }

  async platformMetrics() {
    const [companies, users, orders, sessions, evidence, warehouses] =
      await Promise.all([
        prisma.company.count(),
        prisma.user.count(),
        prisma.order.count(),
        prisma.packingSession.count(),
        prisma.evidenceMedia.count(),
        prisma.warehouse.count(),
      ]);

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
