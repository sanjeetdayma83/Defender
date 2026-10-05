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
  if (value !== null && value !== undefined && typeof value === "object") {
    return Number(String(value));
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

function joinAddress(
  addressLine1: string | null | undefined,
  addressLine2: string | null | undefined,
): string | null {
  const parts = [addressLine1, addressLine2]
    .map((value) => value?.trim())
    .filter((value): value is string => Boolean(value));

  return parts.length > 0 ? parts.join(", ") : null;
}

type LegacyCompanyRow = {
  id: string;
  name: string | null;
  code: string | null;
  plan: string | null;
  isActive: boolean | null;
  createdAt: Date | string | null;
  updatedAt: Date | string | null;
};

type CompanyAggregate = {
  userCount: number;
  activeUserCount: number;
  warehouseCount: number;
  orderCountThisMonth: number;
};

async function getCompanyAggregates(
  companyIds: string[],
): Promise<Map<string, CompanyAggregate>> {
  const result = new Map<string, CompanyAggregate>();

  for (const companyId of companyIds) {
    const [users, activeUsers, warehouses, orders] = await Promise.all([
      prisma.$queryRaw<{ count: bigint }[]>`
        SELECT COUNT(*)::bigint AS count
        FROM "User"
        WHERE "companyId" = ${companyId}
      `,
      prisma.$queryRaw<{ count: bigint }[]>`
        SELECT COUNT(*)::bigint AS count
        FROM "User"
        WHERE "companyId" = ${companyId}
          AND (
            LOWER(COALESCE(status, '')) = 'active'
            OR status IS NULL
          )
      `,
      prisma.$queryRaw<{ count: bigint }[]>`
        SELECT COUNT(*)::bigint AS count
        FROM "Warehouse"
        WHERE "companyId" = ${companyId}
      `,
      prisma.$queryRaw<{ count: bigint }[]>`
        SELECT COUNT(*)::bigint AS count
        FROM "Order"
        WHERE "companyId" = ${companyId}
          AND "createdAt" >= ${startOfCurrentMonth()}
      `,
    ]);

    result.set(companyId, {
      userCount: toInt(users[0]?.count),
      activeUserCount: toInt(activeUsers[0]?.count),
      warehouseCount: toInt(warehouses[0]?.count),
      orderCountThisMonth: toInt(orders[0]?.count),
    });
  }

  return result;
}

async function getRegions(): Promise<string[]> {
  try {
    const rows = await prisma.$queryRaw<{ state: string | null }[]>`
      SELECT DISTINCT NULLIF(TRIM(address->>'state'), '') AS state FROM "Company" WHERE address->>'state' IS NOT NULL
      ORDER BY state ASC
    `;

    return rows
      .map((row) => row.state)
      .filter((value): value is string => Boolean(value));
  } catch {
    return [];
  }
}

async function getPlans(): Promise<string[]> {
  try {
    const rows = await prisma.$queryRaw<{ plan: string | null }[]>`
      SELECT DISTINCT NULLIF(TRIM(plan::text), '') AS plan FROM "Company" WHERE plan IS NOT NULL
      ORDER BY plan ASC
    `;

    return rows
      .map((row) => row.plan)
      .filter((value): value is string => Boolean(value));
  } catch {
    return [];
  }
}

async function buildCompany(
  company: LegacyCompanyRow,
  aggregate: CompanyAggregate,
): Promise<PlatformCompanyRow> {
  const companyId = company.id;

  let billing: any = null;
  let wallet: any = null;
  let activity: any[] = [];
  let storageUsedBytes = 0;

  try {
    const rows = await prisma.$queryRaw<any[]>`
      SELECT *
      FROM "Company"
      WHERE id = ${companyId}
      LIMIT 1
    `;
    billing = rows[0] ?? null;
  } catch {
    billing = null;
  }

  try {
    const rows = await prisma.$queryRaw<any[]>`
      SELECT *
      FROM scan_wallets
      WHERE company_id = ${companyId}
      ORDER BY created_at DESC
      LIMIT 1
    `;
    wallet = rows[0] ?? null;
  } catch {
    wallet = null;
  }

  try {
    const rows = await prisma.$queryRaw<any[]>`
      SELECT
        al.id,
        al.action,
        al.description,
        u.name AS "userName",
        al."createdAt"
      FROM "AuditLog" al
      LEFT JOIN "User" u ON u.id = al."userId"
      WHERE al."companyId" = ${companyId}
      ORDER BY al."createdAt" DESC
      LIMIT 8
    `;
    activity = rows;
  } catch {
    activity = [];
  }

  try {
    const rows = await prisma.$queryRaw<{ total: bigint | null }[]>`
      SELECT COALESCE(SUM("sizeBytes"), 0)::bigint AS total
      FROM "StorageObject"
      WHERE "companyId" = ${companyId}
    `;
    storageUsedBytes = toInt(rows[0]?.total);
  } catch {
    storageUsedBytes = 0;
  }

  const status = company.isActive === false ? "INACTIVE" : "ACTIVE";
  const createdAt =
    company.createdAt instanceof Date
      ? company.createdAt.toISOString()
      : company.createdAt
        ? new Date(company.createdAt).toISOString()
        : new Date(0).toISOString();

  return {
    id: company.id,
    name: company.name ?? `Company ${company.id}`,
    code: company.code ?? null,
    status,

    userCount: aggregate.userCount,
    activeUserCount: aggregate.activeUserCount,
    warehouseCount: aggregate.warehouseCount,

    planName: company.plan ?? null,
    planCode: company.plan ?? null,
    subscriptionStatus: null,

    createdAt,

    gstin:
      billing?.gstin ??
      billing?.GSTIN ??
      billing?.gst_number ??
      null,

    billingEmail:
      billing?.billingEmail ??
      billing?.billing_email ??
      billing?.email ??
      null,

    billingPhone:
      billing?.billingPhone ??
      billing?.billing_phone ??
      billing?.phone ??
      null,

    address: joinAddress(
      billing?.addressLine1 ?? billing?.address,
      billing?.addressLine2,
    ),

    city: billing?.city ?? null,
    state: billing?.state ?? null,
    country: billing?.country ?? "India",

    storageUsedBytes,
    storageQuotaBytes: null,

    orderCountThisMonth: aggregate.orderCountThisMonth,

    revenuePaise: 0,
    planRevenuePaise: 0,
    topupRevenuePaise: 0,

    planPricePaise: null,
    includedScans: null,
    maxWarehouses: null,
    maxOperators: null,

    walletBalance: toInt(
      wallet?.balance ??
      wallet?.balance_credits ??
      wallet?.available_credits,
    ),

    walletAllocated: toInt(
      wallet?.lifetime_allocated ??
      wallet?.allocated_credits ??
      wallet?.total_allocated,
    ),

    walletConsumed: toInt(
      wallet?.lifetime_consumed ??
      wallet?.consumed_credits ??
      wallet?.total_consumed,
    ),

    recentActivity: activity.map((row) => ({
      id: String(row.id),
      action: String(row.action ?? "ACTIVITY"),
      description: row.description ?? null,
      userName: row.userName ?? null,
      createdAt:
        row.createdAt instanceof Date
          ? row.createdAt.toISOString()
          : new Date(row.createdAt).toISOString(),
    })),
  };
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

    const conditions: string[] = [];
    const params: unknown[] = [];
    let paramIndex = 1;

    if (status === "active") {
      conditions.push(`LOWER(status::text) = 'active'`);
    } else if (status === "inactive") {
      conditions.push(`LOWER(status::text) <> 'active'`);
    }

    if (search) {
      conditions.push(`(
        "companyName" ILIKE ${paramIndex}
        OR code ILIKE $${paramIndex}
      )`);
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (plan && plan !== "All") {
      conditions.push(`LOWER(COALESCE(plan, '')) = LOWER($${paramIndex})`);
      params.push(plan);
      paramIndex++;
    }

    if (region && region !== "All") {
      conditions.push(`LOWER(COALESCE(state, '')) = LOWER($${paramIndex})`);
      params.push(region);
      paramIndex++;
    }

    const whereSql =
      conditions.length > 0
        ? `WHERE ${conditions.join(" AND ")}`
        : "";

    const countRows = await prisma.$queryRawUnsafe<{ count: bigint }[]>(
      `SELECT COUNT(*)::bigint AS count FROM "Company" ${whereSql}`,
      ...params,
    );

    const total = toInt(countRows[0]?.count);

    const offset = (page - 1) * limit;

    const companyParams = [...params, limit, offset];

    const companies = await prisma.$queryRawUnsafe<LegacyCompanyRow[]>(
      `
      SELECT id, "companyName" AS name, NULL::text AS code, plan::text AS plan, (LOWER(status::text) = 'active') AS "isActive", "createdAt", "updatedAt", email, phone, gst, pan, address, "storageUsed", "storageQuota" FROM "Company"
      ${whereSql}
      ORDER BY "createdAt" DESC NULLS LAST, id
      LIMIT $${paramIndex}
      OFFSET $${paramIndex + 1}
      `,
      ...companyParams,
    );

    const aggregates = await getCompanyAggregates(
      companies.map((company) => company.id),
    );

    const items: PlatformCompanyRow[] = [];

    for (const company of companies) {
      items.push(
        await buildCompany(
          company,
          aggregates.get(company.id) ?? {
            userCount: 0,
            activeUserCount: 0,
            warehouseCount: 0,
            orderCountThisMonth: 0,
          },
        ),
      );
    }

    const [
      activeRows,
      inactiveRows,
      trialRows,
      userRows,
      planRows,
      regionRows,
    ] = await Promise.all([
      prisma.$queryRawUnsafe<{ count: bigint }[]>(
        `SELECT COUNT(*)::bigint AS count FROM "Company" ${whereSql} AND LOWER(status::text) = 'active'`.replace(
          "WHERE  AND",
          "WHERE",
        ),
        ...params,
      ).catch(() => [{ count: BigInt(0) }]),

      prisma.$queryRawUnsafe<{ count: bigint }[]>(
        `SELECT COUNT(*)::bigint AS count FROM "Company" ${whereSql} AND LOWER(status::text) <> 'active'`.replace(
          "WHERE  AND",
          "WHERE",
        ),
        ...params,
      ).catch(() => [{ count: BigInt(0) }]),

      Promise.resolve([{ count: BigInt(0) }]),

      prisma.$queryRaw<{ count: bigint }[]>`
        SELECT COUNT(*)::bigint AS count FROM "User"
      `,

      getPlans().then((plans) =>
        plans.map((plan) => ({ name: plan })),
      ),

      getRegions().then((regions) =>
        regions.map((state) => ({ state })),
      ),
    ]);

    const activeCompanies =
      status === "active"
        ? total
        : toInt(activeRows[0]?.count);

    const inactiveCompanies =
      status === "inactive"
        ? total
        : toInt(inactiveRows[0]?.count);

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
        trialCompanies: toInt(trialRows[0]?.count),
        totalUsers: toInt(userRows[0]?.count),
        totalRevenuePaise: 0,
        scanCreditsSold: 0,
      },

      filterOptions: {
        plans: planRows.map((item) => item.name),
        regions: regionRows
          .map((item) => item.state)
          .filter((state): state is string => Boolean(state)),
      },

      items,
    };
  }

  async get(companyId: string): Promise<PlatformCompanyRow | null> {
    const rows = await prisma.$queryRaw<LegacyCompanyRow[]>`
      SELECT id, "companyName" AS name, NULL::text AS code, plan::text AS plan, (LOWER(status::text) = 'active') AS "isActive", "createdAt", "updatedAt", email, phone, gst, pan, address, "storageUsed", "storageQuota" FROM "Company"
      WHERE id = ${companyId}
      LIMIT 1
    `;

    const company = rows[0];

    if (!company) {
      return null;
    }

    const aggregates = await getCompanyAggregates([company.id]);

    return buildCompany(
      company,
      aggregates.get(company.id) ?? {
        userCount: 0,
        activeUserCount: 0,
        warehouseCount: 0,
        orderCountThisMonth: 0,
      },
    );
  }

  async setActive(companyId: string, isActive: boolean) {
    const rows = await prisma.$queryRaw<{
      id: string;
      isActive: boolean;
    }[]>`
      UPDATE "Company"
      SET
        "isActive" = ${isActive},
        "updatedAt" = NOW()
      WHERE id = ${companyId}
      RETURNING id, "isActive"
    `;

    const company = rows[0];

    if (!company) {
      throw new Error("COMPANY_NOT_FOUND");
    }

    return {
      id: company.id,
      isActive: company.isActive,
      status: company.isActive ? "ACTIVE" : "INACTIVE",
    };
  }
}


