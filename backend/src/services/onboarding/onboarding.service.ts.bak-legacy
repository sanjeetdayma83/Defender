import { prisma } from "../../config/prisma.js";
import { entitlementService } from "../plans/entitlement.service.js";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";

type ProfileInput = {
  name?: string;
  email?: string;
};

type CompanyInput = {
  name: string;
  code?: string;
};

type WarehouseInput = {
  name: string;
  code?: string;
};

function clean(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function makeCode(value: string, fallback: string): string {
  const source = clean(value);

  const generated = source
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 30);

  return generated || fallback;
}

export class OnboardingService {
  async getStatus(firebaseUid: string) {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
      include: {
        company: true,
      },
    });

    if (!user) {
      return {
        exists: false,
        complete: false,
        user: null,
        company: null,
        warehouses: [],
      };
    }

    const warehouses = await prisma.warehouse.findMany({
      where: {
        companyId: user.companyId,
      },
      orderBy: {
        createdAt: "asc",
      },
    });

    const complete =
      (user.name ?? "").trim().length > 0 &&
      user.company != null &&
      warehouses.length > 0;

    return {
      exists: true,
      complete,
      user,
      company: user.company,
      warehouses,
    };
  }

  async updateProfile(firebaseUid: string, input: ProfileInput) {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
    });

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    const name = clean(input.name);

    if (!name) {
      throw new Error("NAME_REQUIRED");
    }

    return prisma.user.update({
      where: {
        id: user.id,
      },
      data: {
        name,
      },
      select: {
        id: true,
        firebaseUid: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        companyId: true,
      },
    });
  }

  async updateCompany(firebaseUid: string, input: CompanyInput) {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
    });

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    const name = clean(input.name);

    if (!name) {
      throw new Error("COMPANY_NAME_REQUIRED");
    }

    const code = makeCode(clean(input.code), makeCode(name, "COMPANY"));

    const existingCode = await prisma.company.findFirst({
      where: {
        code,
        id: {
          not: user.companyId,
        },
      },
    });

    if (existingCode) {
      throw new Error("COMPANY_CODE_EXISTS");
    }

    return prisma.company.update({
      where: {
        id: user.companyId,
      },
      data: {
        name,
        code,
      },
    });
  }

  async createWarehouse(firebaseUid: string, input: WarehouseInput) {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
      include: {
        company: true,
      },
    });

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    const name = clean(input.name);

    if (!name) {
      throw new Error("WAREHOUSE_NAME_REQUIRED");
    }

    const code = makeCode(clean(input.code), makeCode(name, "WAREHOUSE"));

    const existingCode = await prisma.warehouse.findFirst({
      where: {
        companyId: user.companyId,
        code,
      },
    });

    if (existingCode) {
      if (existingCode.name.trim().toLowerCase() !== name.toLowerCase()) {
        throw new Error("WAREHOUSE_CODE_EXISTS");
      }

      return existingCode;
    }

    await entitlementService.assertWarehouseCapacity(user.companyId);
    return prisma.warehouse.create({
      data: {
        name,
        code,
        isActive: true,
        companyId: user.companyId,
        country: "India",
      },
    });
  }

  async complete(firebaseUid: string) {
    const status = await this.getStatus(firebaseUid);

    if (!status.exists || !status.user) {
      throw new Error("USER_NOT_FOUND");
    }

    if (!status.company) {
      throw new Error("COMPANY_NOT_FOUND");
    }

    if (status.warehouses.length === 0) {
      throw new Error("WAREHOUSE_REQUIRED");
    }

    if (!(status.user.name ?? "").trim()) {
      throw new Error("NAME_REQUIRED");
    }

    return {
      complete: true,
      user: status.user,
      company: status.company,
      warehouses: status.warehouses,
    };
  }
}

export const onboardingService = new OnboardingService();
