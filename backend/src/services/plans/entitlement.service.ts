import { prisma } from "../../config/prisma.js";
import {
  planConfigurationService,
  type PlanConfiguration,
} from "../billing/plan-configuration.service.js";

export interface PlanEntitlements {
  plan: string;
  includedScans: number;
  maxWarehouses: number | null;
  maxOperators: number | null;
  normalRetentionDays: number;
  storageQuotaBytes: bigint;
}

function toEntitlements(plan: PlanConfiguration): PlanEntitlements {
  return {
    plan: plan.code,
    includedScans: plan.includedScans,
    maxWarehouses: plan.maxWarehouses,
    maxOperators: plan.maxOperators,
    normalRetentionDays: plan.retentionDays,
    storageQuotaBytes: plan.storageQuotaBytes,
  };
}

export class EntitlementService {
  async getEntitlements(plan: string): Promise<PlanEntitlements> {
    const normalized = plan.trim().toLowerCase();

    const configuration =
      await planConfigurationService.getActivePlan(normalized);

    if (!configuration) {
      throw new Error(`Unsupported company plan: ${plan}`);
    }

    return toEntitlements(configuration);
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

    const entitlements =
      await this.getCompanyEntitlements(companyId);

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

    const storageUsed = rows[0].storageUsed;
    const storageQuota =
      entitlements.storageQuotaBytes;

    if (
      storageQuota > 0n &&
      storageUsed + BigInt(additionalBytes) > storageQuota
    ) {
      throw new Error(
        `STORAGE_LIMIT_REACHED:${storageQuota.toString()}`,
      );
    }
  }
}

export const entitlementService = new EntitlementService();
