import { prisma } from "../../config/prisma.js";

export type LiveRole =
  "PLATFORM_ADMIN" | "OWNER" | "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";

export class IdentityService {
  async getByFirebaseUid(firebaseUid: string) {
    return prisma.user.findUnique({
      where: {
        firebaseUid,
      },
      include: {
        company: {
          include: {
            warehouses: {
              where: {
                isActive: true,
              },
              orderBy: {
                name: "asc",
              },
            },
          },
        },
      },
    });
  }

  async bootstrapUser(input: {
    firebaseUid: string;
    email: string;
    name?: string;
  }) {
    const existing = await this.getByFirebaseUid(input.firebaseUid);

    if (existing) {
      return existing;
    }

    const email = input.email.trim().toLowerCase();

    const company = await prisma.company.create({
      data: {
        name: input.name?.trim()
          ? `${input.name.trim()}'s Company`
          : "New Company",
        code: `COMP-${Date.now()}`,
        isActive: true,
      },
    });

    const warehouse = await prisma.warehouse.create({
      data: {
        name: "Main Warehouse",
        code: "MAIN",
        companyId: company.id,
        country: "India",
        isActive: true,
      },
    });

    return prisma.user.create({
      data: {
        firebaseUid: input.firebaseUid,
        email,
        name: input.name?.trim() || email.split("@")[0],
        role: "OWNER",
        isActive: true,
        companyId: company.id,
      },
      include: {
        company: {
          include: {
            warehouses: true,
          },
        },
      },
    });
  }

  async updateProfile(
    firebaseUid: string,
    input: {
      name?: string;
    },
  ) {
    return prisma.user.update({
      where: {
        firebaseUid,
      },
      data: {
        ...(input.name !== undefined
          ? {
              name: input.name.trim(),
            }
          : {}),
      },
      include: {
        company: true,
      },
    });
  }
}
