import { prisma } from "../../config/prisma.js";

export class ProductService {
  async list(companyId: string, search?: string) {
    return prisma.product.findMany({
      where: {
        companyId,
        isActive: true,
        ...(search
          ? {
              OR: [
                {
                  sku: {
                    contains: search,
                    mode: "insensitive",
                  },
                },
                {
                  name: {
                    contains: search,
                    mode: "insensitive",
                  },
                },
              ],
            }
          : {}),
      },
      include: {
        variants: {
          where: {
            isActive: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
      take: 100,
    });
  }

  async get(companyId: string, id: string) {
    return prisma.product.findFirst({
      where: {
        id,
        companyId,
      },
      include: {
        variants: true,
      },
    });
  }
}

export const productService = new ProductService();
