import { prisma } from "../../config/prisma.js";

export class PlanService {
  async listActive() {
    const result = await prisma.$queryRawUnsafe<any[]>(`
      SELECT
        id,
        code,
        name,
        description,
        "pricePaise",
        currency,
        "billingInterval",
        "validityMonths",
        "includedScans",
        "retentionDays",
        "storageQuotaBytes",
        "maxWarehouses",
        "maxOperators",
        "gstPercent",
        "isCommercial",
        "isActive",
        "createdAt",
        "updatedAt"
      FROM plan_configurations
      WHERE "isActive" = true
        AND "isCommercial" = true
      ORDER BY "pricePaise" ASC, code ASC
    `);

    return result;
  }

  async getByCode(code: string) {
    const normalizedCode = code.trim().toLowerCase();

    const result = await prisma.$queryRawUnsafe<any[]>(`
      SELECT
        id,
        code,
        name,
        description,
        "pricePaise",
        currency,
        "billingInterval",
        "validityMonths",
        "includedScans",
        "retentionDays",
        "storageQuotaBytes",
        "maxWarehouses",
        "maxOperators",
        "gstPercent",
        "isCommercial",
        "isActive",
        "createdAt",
        "updatedAt"
      FROM plan_configurations
      WHERE LOWER(code) = $1
      LIMIT 1
    `, normalizedCode);

    return result[0] ?? null;
  }

  async getSubscription(companyId: string) {
    const result = await prisma.$queryRawUnsafe<any[]>(`
      SELECT
        bs.id,
        bs."companyId",
        bs."razorpaySubId",
        bs.plan,
        bs.status,
        bs."currentPeriodStart",
        bs."currentPeriodEnd",
        bs."createdAt",
        bs."updatedAt",
        pc.id AS "planConfigurationId",
        pc.code AS "planCode",
        pc.name AS "planName",
        pc.description AS "planDescription",
        pc."pricePaise",
        pc.currency,
        pc."billingInterval",
        pc."validityMonths",
        pc."includedScans",
        pc."retentionDays",
        pc."storageQuotaBytes",
        pc."maxWarehouses",
        pc."maxOperators",
        pc."gstPercent",
        pc."isCommercial",
        pc."isActive"
      FROM "BillingSubscription" bs
      LEFT JOIN plan_configurations pc
        ON LOWER(pc.code) = LOWER(bs.plan::text)
      WHERE bs."companyId" = $1
      LIMIT 1
    `, companyId);

    return result[0] ?? null;
  }

  async subscribeCompany(_input: {
    companyId: string;
    planId: string;
    billingInterval?: "MONTHLY" | "YEARLY";
  }) {
    throw new Error(
      "SUBSCRIPTION_CHANGES_REQUIRE_BILLING: use the Razorpay billing flow."
    );
  }
}

export const planService = new PlanService();
