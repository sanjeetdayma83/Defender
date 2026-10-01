import { prisma } from "../../config/prisma.js";

export type EntitlementPlan =
  | "free"
  | "starter"
  | "growth"
  | "enterprise";

export interface PlanEntitlements {
  plan: EntitlementPlan;
  includedScans: number;
  maxWarehouses: number | null;
  maxOperators: number | null;
  normalRetentionDays: number;
}

const ENTITLEMENTS: Record<EntitlementPlan, PlanEntitlements> = {
  free: {
    plan: "free",
    includedScans: 0,
    maxWarehouses: 1,
    maxOperators: 0,
    normalRetentionDays: 30,
  },

  starter: {
    plan: "starter",
    includedScans: 5100,
    maxWarehouses: 1,
    maxOperators: 3,
    normalRetentionDays: 30,
  },

  growth: {
    plan: "growth",
    includedScans: 22200,
    maxWarehouses: 3,
    maxOperators: 10,
    normalRetentionDays: 30,
  },

  enterprise: {
    plan: "enterprise",
    includedScans: 56200,
    maxWarehouses: null,
    maxOperators: null,
    normalRetentionDays: 30,
  },
};

export class EntitlementService {
  getEntitlements(plan: string): PlanEntitlements {
    const normalized = plan.trim().toLowerCase() as EntitlementPlan;

    const entitlements = ENTITLEMENTS[normalized];

    if (!entitlements) {
      throw new Error(`Unsupported company plan: ${plan}`);
    }

    return entitlements;
  }

  async getCompanyEntitlements(
    companyId: string,
  ): Promise<PlanEntitlements> {
    const rows = await prisma.$queryRawUnsafe<
      Array<{ plan: string }>
    >(
      `
      SELECT plan::text AS plan
      FROM "Company"
      WHERE id = $1
      LIMIT 1
      `,
      companyId,
    );

    if (!rows[0]) {
      throw new Error(`Company not found: ${companyId}`);
    }

    return this.getEntitlements(rows[0].plan);
  }

  async assertWarehouseCapacity(companyId: string): Promise<void> {
    const entitlements =
      await this.getCompanyEntitlements(companyId);

    if (entitlements.maxWarehouses === null) {
      return;
    }

    const rows = await prisma.$queryRawUnsafe<
      Array<{ count: bigint }>
    >(
      `
      SELECT COUNT(*)::bigint AS count
      FROM "Warehouse"
      WHERE "companyId" = $1
        AND COALESCE("isActive", true) = true
      `,
      companyId,
    );

    const currentCount = Number(rows[0]?.count ?? 0);

    if (currentCount >= entitlements.maxWarehouses) {
      throw new Error(
        `WAREHOUSE_LIMIT_REACHED:${entitlements.maxWarehouses}`,
      );
    }
  }

  async assertOperatorCapacity(companyId: string): Promise<void> {
    const entitlements =
      await this.getCompanyEntitlements(companyId);

    if (entitlements.maxOperators === null) {
      return;
    }

    const rows = await prisma.$queryRawUnsafe<
      Array<{ count: bigint }>
    >(
      `
      SELECT COUNT(*)::bigint AS count
      FROM "User"
      WHERE "companyId" = $1
        AND COALESCE("status"::text, 'active') = 'active'
      `,
      companyId,
    );

    const currentCount = Number(rows[0]?.count ?? 0);

    if (currentCount >= entitlements.maxOperators) {
      throw new Error(
        `OPERATOR_LIMIT_REACHED:${entitlements.maxOperators}`,
      );
    }
  }

  async assertStorageCapacity(
    companyId: string,
    additionalBytes: number,
  ): Promise<void> {
    if (
      !Number.isInteger(additionalBytes) ||
      additionalBytes < 0
    ) {
      throw new Error(
        "additionalBytes must be a non-negative integer.",
      );
    }

    const rows = await prisma.$queryRawUnsafe<
      Array<{
        storageUsed: bigint;
        storageQuota: bigint;
      }>
    >(
      `
      SELECT
        COALESCE("storageUsed", 0)::bigint AS "storageUsed",
        COALESCE("storageQuota", 0)::bigint AS "storageQuota"
      FROM "Company"
      WHERE id = $1
      LIMIT 1
      `,
      companyId,
    );

    if (!rows[0]) {
      throw new Error(`Company not found: ${companyId}`);
    }

    const storageUsed = Number(rows[0].storageUsed);
    const storageQuota = Number(rows[0].storageQuota);

    if (storageUsed + additionalBytes > storageQuota) {
      throw new Error(
        `STORAGE_QUOTA_EXCEEDED:${storageQuota}`,
      );
    }
  }

  async getStorageUsage(companyId: string) {
    const rows = await prisma.$queryRawUnsafe<
      Array<{
        storageUsed: bigint;
        storageQuota: bigint;
      }>
    >(
      `
      SELECT
        COALESCE("storageUsed", 0)::bigint AS "storageUsed",
        COALESCE("storageQuota", 0)::bigint AS "storageQuota"
      FROM "Company"
      WHERE id = $1
      LIMIT 1
      `,
      companyId,
    );

    if (!rows[0]) {
      throw new Error(`Company not found: ${companyId}`);
    }

    return {
      usedBytes: Number(rows[0].storageUsed),
      quotaBytes: Number(rows[0].storageQuota),
    };
  }
}

export const entitlementService = new EntitlementService();
