import { prisma } from "../../config/prisma.js";

export type PlanConfiguration = {
  id: string;
  code: string;
  name: string;
  description: string | null;
  pricePaise: bigint;
  currency: string;
  billingInterval: "MONTHLY" | "YEARLY";
  validityMonths: number;
  includedScans: number;
  retentionDays: number;
  storageQuotaBytes: bigint;
  maxWarehouses: number | null;
  maxOperators: number | null;
  gstPercent: number;
  isCommercial: boolean;
  isActive: boolean;
};

function mapPlan(row: any): PlanConfiguration {
  const billingInterval =
    String(row.billingInterval).toUpperCase() === "YEARLY"
      ? "YEARLY"
      : "MONTHLY";

  return {
    id: String(row.id),
    code: String(row.code).toLowerCase(),
    name: String(row.name),
    description: row.description == null ? null : String(row.description),
    pricePaise: BigInt(row.pricePaise),
    currency: String(row.currency),
    billingInterval,
    validityMonths: Number(row.validityMonths),
    includedScans: Number(row.includedScans),
    retentionDays: Number(row.retentionDays),
    storageQuotaBytes: BigInt(row.storageQuotaBytes),
    maxWarehouses:
      row.maxWarehouses == null ? null : Number(row.maxWarehouses),
    maxOperators:
      row.maxOperators == null ? null : Number(row.maxOperators),
    gstPercent: Number(row.gstPercent),
    isCommercial: Boolean(row.isCommercial),
    isActive: Boolean(row.isActive),
  };
}

export class PlanConfigurationService {
  async getActivePlan(
    planCode: string,
  ): Promise<PlanConfiguration | null> {
    const normalizedCode = String(planCode ?? "").trim().toLowerCase();

    if (!normalizedCode) {
      return null;
    }

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        "id",
        "code",
        "name",
        "description",
        "pricePaise",
        "currency",
        "billingInterval",
        "validityMonths",
        "includedScans",
        "retentionDays",
        "storageQuotaBytes",
        "maxWarehouses",
        "maxOperators",
        "gstPercent",
        "isCommercial",
        "isActive"
      FROM "plan_configurations"
      WHERE "code" = $1
        AND "isActive" = TRUE
      LIMIT 1
      `,
      normalizedCode,
    );

    if (rows.length === 0) {
      return null;
    }

    return mapPlan(rows[0]);
  }

  async requireActiveCommercialPlan(
    planCode: string,
  ): Promise<PlanConfiguration> {
    const plan = await this.getActivePlan(planCode);

    if (!plan || !plan.isCommercial) {
      throw new Error("PLAN_NOT_FOUND");
    }

    if (plan.pricePaise <= 0n) {
      throw new Error("PLAN_PRICE_INVALID");
    }

    if (plan.includedScans <= 0) {
      throw new Error("PLAN_SCAN_ALLOCATION_INVALID");
    }

    if (plan.validityMonths <= 0) {
      throw new Error("PLAN_VALIDITY_INVALID");
    }

    if (plan.retentionDays <= 0) {
      throw new Error("PLAN_RETENTION_INVALID");
    }

    return plan;
  }

  async listActiveCommercialPlans(): Promise<PlanConfiguration[]> {
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        "id",
        "code",
        "name",
        "description",
        "pricePaise",
        "currency",
        "billingInterval",
        "validityMonths",
        "includedScans",
        "retentionDays",
        "storageQuotaBytes",
        "maxWarehouses",
        "maxOperators",
        "gstPercent",
        "isCommercial",
        "isActive"
      FROM "plan_configurations"
      WHERE "isActive" = TRUE
        AND "isCommercial" = TRUE
      ORDER BY "pricePaise" ASC, "code" ASC
      `,
    );

    return rows.map(mapPlan);
  }
}

export const planConfigurationService =
  new PlanConfigurationService();
