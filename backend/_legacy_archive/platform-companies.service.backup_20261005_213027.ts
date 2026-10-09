import { prisma } from "../../config/prisma.js";

export type PlatformCompanyActivity = {
  id: string;
  action: string;
  description: string | null;
  userName: string | null;
  createdAt: string;
};

export type PlatformCompanyRow = {
  id: string;
  name: string;
  code: string | null;
  status: string;

  userCount: number;
  activeUserCount: number;
  warehouseCount: number;

  planName: string | null;
  planCode: string | null;
  subscriptionStatus: string | null;

  createdAt: string;

  gstin: string | null;
  billingEmail: string | null;
  billingPhone: string | null;

  address: string | null;
  city: string | null;
  state: string | null;
  country: string | null;

  storageUsedBytes: number;
  storageQuotaBytes: number | null;

  orderCountThisMonth: number;

  revenuePaise: number;
  planRevenuePaise: number;
  topupRevenuePaise: number;

  planPricePaise: number | null;
  includedScans: number | null;
  maxWarehouses: number | null;
  maxOperators: number | null;

  walletBalance: number;
  walletAllocated: number;
  walletConsumed: number;

  recentActivity: PlatformCompanyActivity[];
};

export type PlatformCompaniesSummary = {
  totalCompanies: number;
  activeCompanies: number;
  inactiveCompanies: number;
  trialCompanies: number;
  totalUsers: number;
  totalRevenuePaise: number;
  scanCreditsSold: number;
};

export type PlatformCompaniesResult = {
  page: number;
  limit: number;
  total: number;
  pages: number;
  summary: PlatformCompaniesSummary;
  filterOptions: {
    plans: string[];
    regions: string[];
  };
  items: PlatformCompanyRow[];
};

function toNumber(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "bigint") return Number(value);
  if (value && typeof value === "object" && "toString" in value) {
    return Number(value.toString());
  }
  return Number(value ?? 0);
}

function toInt(value: unknown): number {
  const n = toNumber(value);
  return Number.isFinite(n) ? Math.trunc(n) : 0;
}

function toNullableInt(value: unknown): number | null {
  if (value === null || value === undefined) return null;

  const n = toNumber(value);
  return Number.isFinite(n) ? Math.trunc(n) : null;
}

function startOfCurrentMonth(): Date {
  const now = new Date();
  return new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      1,
      0,
      0,
      0,
      0,
    ),
  );
}

function storageQuotaFromPlan(plan: {
  features: Array<{
    featureCode: string;
    quantity: number | null;
  }>;
} | null): number | null {
  if (!plan) return null;

  const feature = plan.features.find(
    (item) =>
      item.featureCode.toLowerCase() === "storage" ||
      item.featureCode.toLowerCase() === "storage_bytes" ||
      item.featureCode.toLowerCase() === "storage_quota",
  );

  if (!feature || feature.quantity === null) return null;

  return feature.quantity;
}

function joinAddress(
  addressLine1: string | null | undefined,
  addressLine2: string | null | undefined,
): string | null {
  const parts = [addressLine1, addressLine2]
    .map((value) => value?.trim())
    .filter((value): value is string => Boolean(value));

  return parts.length > 0 ? parts.join(", ") : null;
}

export class PlatformCompaniesService {
  async list(opts: {
    search?: string;
    status?: "all" | "active" | "inactive";
    plan?: string;
    region?: string;
    page?: number;
    limit?: number;
  }): Promise<PlatformCompaniesResult> {
    const page = Math.max(opts.page ?? 1, 1);
    const limit = Math.min(Math.max(opts.limit ?? 10, 1), 100);
    const search = (opts.search ?? "").trim();
    const plan = (opts.plan ?? "").trim();
    const region = (opts.region ?? "").trim();
    const status = opts.status ?? "all";

    const where: any = {};

    if (status === "active") {
      where.isActive = true;
    } else if (status === "inactive") {
      where.isActive = false;
    }

    if (search) {
      where.OR = [
        {
          name: {
            contains: search,
            mode: "insensitive",
          },
        },
        {
          code: {
            contains: search,
            mode: "insensitive",
          },
        },
      ];
    }

    if (plan && plan !== "All") {
      where.subscription = {
        is: {
          plan: {
            name: {
              equals: plan,
            },
          },
        },
      };
    }

    if (region && region !== "All") {
      where.billingProfile = {
        is: {
          state: {
            equals: region,
          },
        },
      };
    }

    const currentMonth = startOfCurrentMonth();

    const [
      total,
      companies,
      activeCompanies,
      inactiveCompanies,
      trialCompanies,
      totalUsers,
      scanCreditsSold,
      successfulPayments,
      plans,
      regions,
    ] = await Promise.all([
      prisma.company.count({ where }),

      prisma.company.findMany({
        where,
        orderBy: {
          createdAt: "desc",
        },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          _count: {
            select: {
              users: true,
              warehouses: true,
            },
          },

          users: {
            where: {
              isActive: true,
            },
            select: {
              id: true,
            },
          },

          billingProfile: true,

          subscription: {
            include: {
              plan: {
                include: {
                  features: true,
                },
              },
            },
          },

          scanWallet: true,

          storageObjects: {
            select: {
              sizeBytes: true,
            },
          },

          orders: {
            where: {
              createdAt: {
                gte: currentMonth,
              },
            },
            select: {
              id: true,
            },
          },

          payments: {
            where: {
              status: "SUCCESS",
              createdAt: {
                gte: currentMonth,
              },
            },
            select: {
              totalPaise: true,
              createdAt: true,
              items: {
                select: {
                  itemType: true,
                  totalPaise: true,
                },
              },
            },
          },

          auditLogs: {
            orderBy: {
              createdAt: "desc",
            },
            take: 8,
            include: {
              user: {
                select: {
                  name: true,
                },
              },
            },
          },
        },
      }),

      prisma.company.count({
        where: {
          ...where,
          isActive: true,
        },
      }),

      prisma.company.count({
        where: {
          ...where,
          isActive: false,
        },
      }),

      prisma.company.count({
        where: {
          ...where,
          subscription: {
            is: {
              status: "TRIALING",
            },
          },
        },
      }),

      prisma.user.count(),

      prisma.scanTransaction.aggregate({
        where: {
          type: "TOPUP",
        },
        _sum: {
          credits: true,
        },
      }),

      prisma.payment.aggregate({
        where: {
          status: "SUCCESS",
          createdAt: {
            gte: currentMonth,
          },
        },
        _sum: {
          totalPaise: true,
        },
      }),

      prisma.plan.findMany({
        select: {
          name: true,
        },
        orderBy: {
          sortOrder: "asc",
        },
      }),

      prisma.billingProfile.findMany({
        where: {
          state: {
            not: null,
          },
        },
        select: {
          state: true,
        },
        distinct: ["state"],
        orderBy: {
          state: "asc",
        },
      }),
    ]);

    const items: PlatformCompanyRow[] = companies.map((company) => {
      const storageUsedBytes = company.storageObjects.reduce(
        (sum, object) => sum + toInt(object.sizeBytes),
        0,
      );

      let revenuePaise = 0;
      let planRevenuePaise = 0;
      let topupRevenuePaise = 0;

      for (const payment of company.payments) {
        revenuePaise += toInt(payment.totalPaise);

        for (const item of payment.items) {
          const itemTotal = toInt(item.totalPaise);

          if (item.itemType === "PLAN") {
            planRevenuePaise += itemTotal;
          }

          if (item.itemType === "EXTRA_SCAN_PACK") {
            topupRevenuePaise += itemTotal;
          }
        }
      }

      const planData = company.subscription?.plan ?? null;

      const recentActivity: PlatformCompanyActivity[] =
        company.auditLogs.map((log) => ({
          id: log.id,
          action: String(log.action),
          description: log.description ?? null,
          userName: log.user?.name ?? null,
          createdAt: log.createdAt.toISOString(),
        }));

      return {
        id: company.id,
        name: company.name,
        code: company.code ?? null,
        status: company.isActive ? "ACTIVE" : "INACTIVE",

        userCount: company._count.users,
        activeUserCount: company.users.length,
        warehouseCount: company._count.warehouses,

        planName: planData?.name ?? null,
        planCode: planData?.code ?? null,
        subscriptionStatus: company.subscription?.status ?? null,

        createdAt: company.createdAt.toISOString(),

        gstin: company.billingProfile?.gstin ?? null,
        billingEmail: company.billingProfile?.billingEmail ?? null,
        billingPhone: company.billingProfile?.billingPhone ?? null,

        address: joinAddress(
          company.billingProfile?.addressLine1,
          company.billingProfile?.addressLine2,
        ),
        city: company.billingProfile?.city ?? null,
        state: company.billingProfile?.state ?? null,
        country: company.billingProfile?.country ?? null,

        storageUsedBytes,
        storageQuotaBytes: storageQuotaFromPlan(planData),

        orderCountThisMonth: company.orders.length,

        revenuePaise,
        planRevenuePaise,
        topupRevenuePaise,

        planPricePaise:
          planData?.pricePaise ??
          (planData?.monthlyPrice
            ? Math.round(Number(planData.monthlyPrice) * 100)
            : null),

        includedScans:
          planData?.includedScans ??
          planData?.monthlyScanCredits ??
          null,

        maxWarehouses: planData?.maxWarehouses ?? null,
        maxOperators: planData?.maxOperators ?? null,

        walletBalance: company.scanWallet?.balance ?? 0,
        walletAllocated: company.scanWallet?.lifetimeAllocated ?? 0,
        walletConsumed: company.scanWallet?.lifetimeConsumed ?? 0,

        recentActivity,
      };
    });

    const pages = total === 0 ? 1 : Math.ceil(total / limit);

    return {
      page,
      limit,
      total,
      pages,

      summary: {
        totalCompanies: total,
        activeCompanies,
        inactiveCompanies,
        trialCompanies,
        totalUsers: toInt(totalUsers),
        totalRevenuePaise: toInt(successfulPayments._sum.totalPaise),
        scanCreditsSold: toInt(scanCreditsSold._sum.credits),
      },

      filterOptions: {
        plans: plans.map((item) => item.name),
        regions: regions
          .map((item) => item.state)
          .filter((state): state is string => Boolean(state)),
      },

      items,
    };
  }

  async get(companyId: string): Promise<PlatformCompanyRow | null> {
    const company = await prisma.company.findUnique({
      where: {
        id: companyId,
      },

      include: {
        _count: {
          select: {
            users: true,
            warehouses: true,
          },
        },

        users: {
          where: {
            isActive: true,
          },
          select: {
            id: true,
          },
        },

        billingProfile: true,

        subscription: {
          include: {
            plan: {
              include: {
                features: true,
              },
            },
          },
        },

        scanWallet: true,

        storageObjects: {
          select: {
            sizeBytes: true,
          },
        },

        orders: {
          where: {
            createdAt: {
              gte: startOfCurrentMonth(),
            },
          },
          select: {
            id: true,
          },
        },

        payments: {
          where: {
            status: "SUCCESS",
          },
          select: {
            totalPaise: true,
            createdAt: true,
            items: {
              select: {
                itemType: true,
                totalPaise: true,
              },
            },
          },
        },

        auditLogs: {
          orderBy: {
            createdAt: "desc",
          },
          take: 20,
          include: {
            user: {
              select: {
                name: true,
              },
            },
          },
        },
      },
    });

    if (!company) return null;

    const storageUsedBytes = company.storageObjects.reduce(
      (sum, object) => sum + toInt(object.sizeBytes),
      0,
    );

    let revenuePaise = 0;
    let planRevenuePaise = 0;
    let topupRevenuePaise = 0;

    for (const payment of company.payments) {
      revenuePaise += toInt(payment.totalPaise);

      for (const item of payment.items) {
        const itemTotal = toInt(item.totalPaise);

        if (item.itemType === "PLAN") {
          planRevenuePaise += itemTotal;
        }

        if (item.itemType === "EXTRA_SCAN_PACK") {
          topupRevenuePaise += itemTotal;
        }
      }
    }

    const planData = company.subscription?.plan ?? null;

    return {
      id: company.id,
      name: company.name,
      code: company.code ?? null,
      status: company.isActive ? "ACTIVE" : "INACTIVE",

      userCount: company._count.users,
      activeUserCount: company.users.length,
      warehouseCount: company._count.warehouses,

      planName: planData?.name ?? null,
      planCode: planData?.code ?? null,
      subscriptionStatus: company.subscription?.status ?? null,

      createdAt: company.createdAt.toISOString(),

      gstin: company.billingProfile?.gstin ?? null,
      billingEmail: company.billingProfile?.billingEmail ?? null,
      billingPhone: company.billingProfile?.billingPhone ?? null,

      address: joinAddress(
        company.billingProfile?.addressLine1,
        company.billingProfile?.addressLine2,
      ),
      city: company.billingProfile?.city ?? null,
      state: company.billingProfile?.state ?? null,
      country: company.billingProfile?.country ?? null,

      storageUsedBytes,
      storageQuotaBytes: storageQuotaFromPlan(planData),

      orderCountThisMonth: company.orders.length,

      revenuePaise,
      planRevenuePaise,
      topupRevenuePaise,

      planPricePaise:
        planData?.pricePaise ??
        (planData?.monthlyPrice
          ? Math.round(Number(planData.monthlyPrice) * 100)
          : null),

      includedScans:
        planData?.includedScans ??
        planData?.monthlyScanCredits ??
        null,

      maxWarehouses: planData?.maxWarehouses ?? null,
      maxOperators: planData?.maxOperators ?? null,

      walletBalance: company.scanWallet?.balance ?? 0,
      walletAllocated: company.scanWallet?.lifetimeAllocated ?? 0,
      walletConsumed: company.scanWallet?.lifetimeConsumed ?? 0,

      recentActivity: company.auditLogs.map((log) => ({
        id: log.id,
        action: String(log.action),
        description: log.description ?? null,
        userName: log.user?.name ?? null,
        createdAt: log.createdAt.toISOString(),
      })),
    };
  }

  async setActive(companyId: string, isActive: boolean) {
    const company = await prisma.company.update({
      where: {
        id: companyId,
      },
      data: {
        isActive,
      },
      select: {
        id: true,
        isActive: true,
      },
    });

    return {
      id: company.id,
      isActive: company.isActive,
      status: company.isActive ? "ACTIVE" : "INACTIVE",
    };
  }
}