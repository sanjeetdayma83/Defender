export type CommercialPlanCode =
  | "starter"
  | "growth"
  | "enterprise";

export interface CommercialPlanDefinition {
  code: CommercialPlanCode;
  pricePaise: number;
  validityMonths: number;
  includedScans: number;
  maxWarehouses: number | null;
  maxOperators: number | null;
  retentionDays: number;
}

export const COMMERCIAL_PLANS: Record<
  CommercialPlanCode,
  CommercialPlanDefinition
> = {
  starter: {
    code: "starter",
    pricePaise: 500000,
    validityMonths: 3,
    includedScans: 5100,
    maxWarehouses: 1,
    maxOperators: 3,
    retentionDays: 30,
  },

  growth: {
    code: "growth",
    pricePaise: 2000000,
    validityMonths: 6,
    includedScans: 22200,
    maxWarehouses: 3,
    maxOperators: 10,
    retentionDays: 30,
  },

  enterprise: {
    code: "enterprise",
    pricePaise: 4500000,
    validityMonths: 12,
    includedScans: 56200,
    maxWarehouses: null,
    maxOperators: null,
    retentionDays: 30,
  },
};

export function getCommercialPlan(
  planCode: string,
): CommercialPlanDefinition | null {
  const normalized = planCode.trim().toLowerCase();

  if (
    normalized !== "starter" &&
    normalized !== "growth" &&
    normalized !== "enterprise"
  ) {
    return null;
  }

  return COMMERCIAL_PLANS[normalized];
}
