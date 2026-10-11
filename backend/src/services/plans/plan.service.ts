import { prisma } from "../../config/prisma.js";

export class PlanService {
  async listActive() {
    return prisma.$queryRawUnsafe<any[]>(`
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
        "updatedAt",
        "maxOrdersPerMonth"
      FROM public.plans
      WHERE "isActive" = true
        AND "isCommercial" = true
      ORDER BY "pricePaise" ASC, code ASC
    `);
  }

  async getByCode(code: string) {
    const normalizedCode = code.trim().toLowerCase();

    const rows = await prisma.$queryRawUnsafe<any[]>(`
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
        "updatedAt",
        "maxOrdersPerMonth"
      FROM public.plans
      WHERE LOWER(code) = $1
      LIMIT 1
    `, normalizedCode);

    return rows[0] ?? null;
  }

  async getSubscription(companyId: string) {
    const rows = await prisma.$queryRawUnsafe<any[]>(`
      SELECT
        s.id,
        s."companyId",
        s."providerSubscriptionId" AS "razorpaySubId",
        p.code AS plan,
        s.status::text AS status,
        s."currentPeriodStart",
        s."currentPeriodEnd",
        s."createdAt",
        s."updatedAt",
        p.id AS "planConfigurationId",
        p.code AS "planCode",
        p.name AS "planName",
        p.description AS "planDescription",
        p."pricePaise",
        p.currency,
        p."billingInterval",
        p."validityMonths",
        p."includedScans",
        p."retentionDays",
        p."storageQuotaBytes",
        p."maxWarehouses",
        p."maxOperators",
        p."gstPercent",
        p."isCommercial",
        p."isActive",
        p."maxOrdersPerMonth"
      FROM public.subscriptions s
      LEFT JOIN public.plans p
        ON p.id = s."planId"
      WHERE s."companyId" = $1
      ORDER BY s."createdAt" DESC
      LIMIT 1
    `, companyId);

    return rows[0] ?? null;
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
