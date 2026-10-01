import { prisma } from "../../config/prisma.js";

export interface BillingContext {
  companyId: string;
  companyName: string;
  email: string;
  plan: string;
  companyStatus: string;
  subscription: {
    id: string;
    razorpaySubId: string | null;
    plan: string;
    status: string;
    currentPeriodStart: Date;
    currentPeriodEnd: Date;
  } | null;
}

export class BillingContextService {
  async getCompanyBillingContext(companyId: string): Promise<BillingContext | null> {
    const companies = await prisma.$queryRawUnsafe<Array<{
      id: string;
      companyName: string;
      email: string;
      plan: string;
      status: string;
    }>>(`
      SELECT
        id,
        "companyName",
        email,
        plan::text AS plan,
        status::text AS status
      FROM "Company"
      WHERE id = $1
      LIMIT 1
    `, companyId);

    const company = companies[0];

    if (!company) {
      return null;
    }

    const subscriptions = await prisma.$queryRawUnsafe<Array<{
      id: string;
      razorpaySubId: string | null;
      plan: string;
      status: string;
      currentPeriodStart: Date;
      currentPeriodEnd: Date;
    }>>(`
      SELECT
        id,
        "razorpaySubId",
        plan::text AS plan,
        status,
        "currentPeriodStart",
        "currentPeriodEnd"
      FROM "BillingSubscription"
      WHERE "companyId" = $1
      ORDER BY "createdAt" DESC
      LIMIT 1
    `, companyId);

    return {
      companyId: company.id,
      companyName: company.companyName,
      email: company.email,
      plan: company.plan,
      companyStatus: company.status,
      subscription: subscriptions[0] ?? null,
    };
  }
}

export const billingContextService = new BillingContextService();

