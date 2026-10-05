import { prisma } from "../../config/prisma.js";

type Row = Record<string, unknown>;

async function queryRows(sql: string): Promise<Row[]> {
  return prisma.$queryRawUnsafe<Row[]>(sql);
}

function one<T extends Row>(rows: T[]): T {
  return rows[0] ?? ({} as T);
}

function numberValue(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "bigint") return Number(value);
  return Number(value ?? 0) || 0;
}

function stringValue(value: unknown): string {
  return value == null ? "" : String(value);
}

function jsonSafe(value: unknown): unknown {
  if (typeof value === "bigint") return value.toString();

  if (Array.isArray(value)) {
    return value.map(jsonSafe);
  }

  if (value && typeof value === "object") {
    const result: Record<string, unknown> = {};

    for (const [key, item] of Object.entries(value)) {
      result[key] = jsonSafe(item);
    }

    return result;
  }

  return value;
}

export class DashboardService {
  async companyMetrics(companyId: string) {
    const orders = one(
      await queryRows(`
        SELECT COUNT(*)::int AS count
        FROM "Order"
        WHERE "companyId" = '${companyId}'
      `),
    );

    return {
      orders: numberValue(orders.count),
      products: 0,
      warehouses: 0,
      users: 0,
      sessions: 0,
      evidence: 0,
    };
  }

  async platformMetrics() {
    const core = one(
      await queryRows(`
        SELECT
          (SELECT COUNT(*) FROM "Company")::int AS companies,
          (SELECT COUNT(*) FROM "User")::int AS users,
          (SELECT COUNT(*) FROM "Warehouse")::int AS warehouses,
          (SELECT COUNT(*) FROM "Order")::int AS orders,
          (SELECT COUNT(*) FROM "Recording")::int AS recordings,
          (SELECT COUNT(*) FROM "Evidence")::int AS evidence,
          (SELECT COUNT(*) FROM "RecordingSegment")::int AS recording_segments
      `),
    );

    const revenue = one(
      await queryRows(`
        SELECT
          COUNT(*)::int AS payment_count,
          COALESCE(SUM("amountPaise"), 0)::bigint AS subtotal_paise,
          COALESCE(SUM("gstPaise"), 0)::bigint AS gst_paise,
          COALESCE(SUM("totalPaise"), 0)::bigint AS total_paise
        FROM "BillingPayment"
        WHERE LOWER("status") = 'success'
      `),
    );

    const activeSubscriptions = one(
      await queryRows(`
        SELECT COUNT(*)::int AS count
        FROM "BillingSubscription"
        WHERE LOWER("status") = 'active'
      `),
    );

    const subscriptionStatus = await queryRows(`
      SELECT
        LOWER("status"::text) AS status,
        COUNT(*)::int AS count
      FROM "BillingSubscription"
      GROUP BY LOWER("status"::text)
      ORDER BY count DESC
    `);

    const usersAccess = one(
      await queryRows(`
        SELECT
          COUNT(*)::int AS total_users,
          COUNT(*) FILTER (
            WHERE LOWER("status"::text) = 'active'
          )::int AS active_users,
          COUNT(*) FILTER (
            WHERE LOWER("status"::text) <> 'active'
          )::int AS inactive_users,
          COUNT(*) FILTER (
            WHERE UPPER("role"::text) IN ('SUPER_ADMIN', 'PLATFORM_ADMIN')
          )::int AS platform_admins,
          COUNT(*) FILTER (
            WHERE LOWER("role"::text) IN ('company_admin', 'owner')
          )::int AS company_admins,
          COUNT(*) FILTER (
            WHERE LOWER("role"::text) IN ('packing_operator', 'operator')
          )::int AS operators
        FROM "User"
      `),
    );

    const companiesOverview = one(
      await queryRows(`
        SELECT
          COUNT(*)::int AS total_companies,
          COUNT(*) FILTER (
            WHERE LOWER("status"::text) = 'active'
          )::int AS active_companies,
          COUNT(*) FILTER (
            WHERE "createdAt" >= date_trunc('month', CURRENT_TIMESTAMP)
          )::int AS new_this_month,
          COUNT(*) FILTER (
            WHERE LOWER("status"::text) <> 'active'
          )::int AS inactive_companies
        FROM "Company"
      `),
    );

    const storage = one(
      await queryRows(`
        SELECT
          COALESCE(SUM("storageUsed"), 0)::bigint AS used_bytes,
          COALESCE(SUM("storageQuota"), 0)::bigint AS quota_bytes
        FROM "Company"
      `),
    );

    const wallet = one(
      await queryRows(`
        SELECT
          COALESCE(SUM("balance"), 0)::bigint AS balance,
          COALESCE(SUM("lifetimeAllocated"), 0)::bigint AS allocated,
          COALESCE(SUM("lifetimeConsumed"), 0)::bigint AS consumed
        FROM scan_wallets
      `),
    );

    const scanTransactions = await queryRows(`
      SELECT
        st."id",
        st."companyId",
        COALESCE(c."companyName", 'Unknown Company') AS "companyName",
        st."type",
        st."credits",
        st."createdAt"
      FROM scan_transactions st
      LEFT JOIN "Company" c
        ON c."id" = st."companyId"
      WHERE UPPER(st."type") IN ('TOPUP', 'ALLOCATION', 'REFUND', 'ADJUSTMENT')
      ORDER BY st."createdAt" DESC
      LIMIT 10
    `);

    const recentUsers = await queryRows(`
      SELECT
        u."id",
        u."name",
        u."email",
        u."role"::text AS role,
        u."status"::text AS status,
        u."createdAt",
        u."lastLoginAt",
        COALESCE(c."companyName", 'Platform') AS "companyName"
      FROM "User" u
      LEFT JOIN "Company" c
        ON c."id" = u."companyId"
      ORDER BY u."createdAt" DESC
      LIMIT 10
    `);

    const recentPayments = await queryRows(`
      SELECT
        bp."id",
        bp."companyId",
        COALESCE(c."companyName", 'Unknown Company') AS "companyName",
        bp."provider",
        bp."status",
        bp."plan",
        bp."billingInterval",
        bp."totalPaise",
        bp."currency",
        bp."paidAt",
        bp."createdAt"
      FROM "BillingPayment" bp
      LEFT JOIN "Company" c
        ON c."id" = bp."companyId"
      ORDER BY bp."createdAt" DESC
      LIMIT 10
    `);

    const monthlyRevenue = await queryRows(`
      SELECT
        TO_CHAR(month_bucket, 'Mon') AS month,
        month_bucket,
        COALESCE(SUM(bp."totalPaise"), 0)::bigint AS revenue_paise,
        COUNT(bp."id")::int AS payment_count
      FROM generate_series(
        date_trunc('month', CURRENT_TIMESTAMP) - INTERVAL '5 months',
        date_trunc('month', CURRENT_TIMESTAMP),
        INTERVAL '1 month'
      ) AS month_bucket
      LEFT JOIN "BillingPayment" bp
        ON bp."createdAt" >= month_bucket
       AND bp."createdAt" < month_bucket + INTERVAL '1 month'
       AND LOWER(bp."status") = 'success'
      GROUP BY month_bucket
      ORDER BY month_bucket
    `);

    const monthlyUsers = await queryRows(`
      SELECT
        TO_CHAR(month_bucket, 'Mon') AS month,
        month_bucket,
        COUNT(u."id")::int AS users
      FROM generate_series(
        date_trunc('month', CURRENT_TIMESTAMP) - INTERVAL '5 months',
        date_trunc('month', CURRENT_TIMESTAMP),
        INTERVAL '1 month'
      ) AS month_bucket
      LEFT JOIN "User" u
        ON u."createdAt" >= month_bucket
       AND u."createdAt" < month_bucket + INTERVAL '1 month'
      GROUP BY month_bucket
      ORDER BY month_bucket
    `);

    const monthlySubscriptions = await queryRows(`
      SELECT
        TO_CHAR(month_bucket, 'Mon') AS month,
        month_bucket,
        COUNT(bs."id")::int AS subscriptions
      FROM generate_series(
        date_trunc('month', CURRENT_TIMESTAMP) - INTERVAL '5 months',
        date_trunc('month', CURRENT_TIMESTAMP),
        INTERVAL '1 month'
      ) AS month_bucket
      LEFT JOIN "BillingSubscription" bs
        ON bs."createdAt" >= month_bucket
       AND bs."createdAt" < month_bucket + INTERVAL '1 month'
      GROUP BY month_bucket
      ORDER BY month_bucket
    `);

    const recordingStatus = await queryRows(`
      SELECT
        LOWER("status"::text) AS status,
        COUNT(*)::int AS count
      FROM "Recording"
      GROUP BY LOWER("status"::text)
      ORDER BY count DESC
    `);

    const evidenceStatus = await queryRows(`
      SELECT
        LOWER("status"::text) AS status,
        COUNT(*)::int AS count
      FROM "Evidence"
      GROUP BY LOWER("status"::text)
      ORDER BY count DESC
    `);

    const result = {
      kpis: {
        totalRevenuePaise: numberValue(revenue.total_paise),
        activeSubscriptions: numberValue(activeSubscriptions.count),
        totalUsers: numberValue(core.users),
        totalCompanies: numberValue(core.companies),
        totalStorageUsedBytes: numberValue(storage.used_bytes),
        totalStorageQuotaBytes: numberValue(storage.quota_bytes),
        totalWarehouses: numberValue(core.warehouses),
        totalOrders: numberValue(core.orders),
        totalRecordings: numberValue(core.recordings),
        totalEvidence: numberValue(core.evidence),
      },

      revenue: {
        paidPaymentCount: numberValue(revenue.payment_count),
        subtotalPaise: numberValue(revenue.subtotal_paise),
        gstPaise: numberValue(revenue.gst_paise),
        totalPaise: numberValue(revenue.total_paise),
        monthly: monthlyRevenue.map((row) => ({
          month: stringValue(row.month),
          revenuePaise: numberValue(row.revenue_paise),
          paymentCount: numberValue(row.payment_count),
        })),
      },

      growth: {
        monthlyUsers: monthlyUsers.map((row) => ({
          month: stringValue(row.month),
          users: numberValue(row.users),
        })),
        monthlySubscriptions: monthlySubscriptions.map((row) => ({
          month: stringValue(row.month),
          subscriptions: numberValue(row.subscriptions),
        })),
      },

      storage: {
        usedBytes: numberValue(storage.used_bytes),
        quotaBytes: numberValue(storage.quota_bytes),
        availableBytes: Math.max(
          0,
          numberValue(storage.quota_bytes) - numberValue(storage.used_bytes),
        ),
      },

      subscriptions: {
        active: numberValue(activeSubscriptions.count),
        status: subscriptionStatus.map((row) => ({
          status: stringValue(row.status),
          count: numberValue(row.count),
        })),
      },

      users: {
        total: numberValue(usersAccess.total_users),
        active: numberValue(usersAccess.active_users),
        inactive: numberValue(usersAccess.inactive_users),
        platformAdmins: numberValue(usersAccess.platform_admins),
        companyAdmins: numberValue(usersAccess.company_admins),
        operators: numberValue(usersAccess.operators),
      },

      companies: {
        total: numberValue(companiesOverview.total_companies),
        active: numberValue(companiesOverview.active_companies),
        inactive: numberValue(companiesOverview.inactive_companies),
        newThisMonth: numberValue(companiesOverview.new_this_month),
      },

      wallet: {
        balance: numberValue(wallet.balance),
        lifetimeAllocated: numberValue(wallet.allocated),
        lifetimeConsumed: numberValue(wallet.consumed),
      },

      recentTopups: scanTransactions.map((row) => ({
        id: stringValue(row.id),
        companyId: stringValue(row.companyId),
        companyName: stringValue(row.companyName),
        type: stringValue(row.type),
        credits: numberValue(row.credits),
        createdAt: row.createdAt,
      })),

      recentUsers: recentUsers.map((row) => ({
        id: stringValue(row.id),
        name: stringValue(row.name),
        email: stringValue(row.email),
        companyName: stringValue(row.companyName),
        role: stringValue(row.role),
        status: stringValue(row.status),
        createdAt: row.createdAt,
        lastLoginAt: row.lastLoginAt,
      })),

      recentPayments: recentPayments.map((row) => ({
        id: stringValue(row.id),
        companyId: stringValue(row.companyId),
        companyName: stringValue(row.companyName),
        provider: stringValue(row.provider),
        status: stringValue(row.status),
        plan: stringValue(row.plan),
        billingInterval: stringValue(row.billingInterval),
        totalPaise: numberValue(row.totalPaise),
        currency: stringValue(row.currency),
        paidAt: row.paidAt,
        createdAt: row.createdAt,
      })),

      operations: {
        orders: numberValue(core.orders),
        recordings: numberValue(core.recordings),
        recordingSegments: numberValue(core.recording_segments),
        evidence: numberValue(core.evidence),
        recordingStatus: recordingStatus.map((row) => ({
          status: stringValue(row.status),
          count: numberValue(row.count),
        })),
        evidenceStatus: evidenceStatus.map((row) => ({
          status: stringValue(row.status),
          count: numberValue(row.count),
        })),
      },
    };

    return jsonSafe(result);
  }
}

export const dashboardService = new DashboardService();
