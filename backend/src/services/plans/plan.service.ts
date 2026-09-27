import { prisma } from "../../config/prisma.js";

export class PlanService {
  async listActive() {
    return prisma.plan.findMany({
      where: {
        isActive: true,
      },
      orderBy: {
        monthlyPrice: "asc",
      },
    });
  }

  async getByCode(code: string) {
    return prisma.plan.findUnique({
      where: {
        code: code.trim().toUpperCase(),
      },
    });
  }

  async getSubscription(companyId: string) {
    return prisma.subscription.findUnique({
      where: {
        companyId,
      },
      include: {
        plan: true,
      },
    });
  }

  async subscribeCompany(input: {
    companyId: string;
    planId: string;
    billingInterval?: "MONTHLY" | "YEARLY";
  }) {
    const plan = await prisma.plan.findUnique({
      where: {
        id: input.planId,
      },
    });

    if (!plan || !plan.isActive) {
      throw new Error("Plan not found or inactive.");
    }

    const now = new Date();

    return prisma.subscription.upsert({
      where: {
        companyId: input.companyId,
      },
      create: {
        companyId: input.companyId,
        planId: plan.id,
        status: "ACTIVE",
        billingInterval: input.billingInterval ?? "MONTHLY",
        provider: "MANUAL",
        currentPeriodStart: now,
      },
      update: {
        planId: plan.id,
        status: "ACTIVE",
        billingInterval: input.billingInterval ?? "MONTHLY",
        currentPeriodStart: now,
        cancelledAt: null,
      },
      include: {
        plan: true,
      },
    });
  }
}

export const planService = new PlanService();
