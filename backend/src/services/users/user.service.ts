import { prisma } from "../../config/prisma.js";

export class UserService {
  async findByFirebaseUid(uid: string) {
    return prisma.user.findUnique({
      where: {
        firebaseUid: uid,
      },

      include: {
        company: true,
      },
    });
  }

  async list(companyId?: string) {
    return prisma.user.findMany({
      where: companyId
        ? {
            companyId,
          }
        : undefined,

      orderBy: {
        createdAt: "desc",
      },
    });
  }
}

export class WarehouseService {
  async list(companyId?: string) {
    return prisma.warehouse.findMany({
      where: companyId
        ? {
            companyId,
          }
        : undefined,

      orderBy: {
        name: "asc",
      },
    });
  }
}
