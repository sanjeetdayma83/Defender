import { prisma } from "../../config/prisma.js";

export class DatabaseOrderService {
  async list(companyId: string, search?: string, status?: string) {
    return prisma.order.findMany({
      where: {
        companyId,
        ...(status
          ? {
              status: status as never,
            }
          : {}),
        ...(search
          ? {
              OR: [
                {
                  externalOrderId: {
                    contains: search,
                    mode: "insensitive",
                  },
                },
                {
                  marketplaceOrderId: {
                    contains: search,
                    mode: "insensitive",
                  },
                },
                {
                  customerName: {
                    contains: search,
                    mode: "insensitive",
                  },
                },
                {
                  shipments: {
                    some: {
                      awb: {
                        contains: search,
                        mode: "insensitive",
                      },
                    },
                  },
                },
              ],
            }
          : {}),
      },
      include: {
        warehouse: true,
        items: {
          include: {
            product: true,
            variant: true,
          },
        },
        shipments: true,
      },
      orderBy: {
        createdAt: "desc",
      },
      take: 100,
    });
  }

  async get(companyId: string, id: string) {
    return prisma.order.findFirst({
      where: {
        id,
        companyId,
      },
      include: {
        warehouse: true,
        items: {
          include: {
            product: {
              include: {
                variants: true,
              },
            },
            variant: true,
          },
        },
        shipments: {
          include: {
            barcodeAliases: true,
          },
        },
      },
    });
  }
}

export const databaseOrderService = new DatabaseOrderService();
