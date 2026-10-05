$ErrorActionPreference = "Stop"

$root = "D:\Loss Defender"
$backendService = Join-Path $root "backend\src\services\platform\platform-companies.service.ts"
$backendController = Join-Path $root "backend\src\controllers\platform\companies.controller.ts"
$backendRoutes = Join-Path $root "backend\src\routes\platform-companies.routes.ts"
$frontendService = Join-Path $root "frontend\lib\services\platform\platform_companies_service.dart"
$frontendScreen = Join-Path $root "frontend\lib\screens\platform\platform_companies_screen.dart"

foreach ($p in @($backendService,$backendController,$backendRoutes,$frontendService,$frontendScreen)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "File not found: $p" }
}

$utf8 = [System.Text.UTF8Encoding]::new($false)

$backendServiceContent = @'
import { prisma } from "../../config/prisma.js";

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
  recentActivity: Array<{
    id: string;
    action: string;
    description: string | null;
    userName: string | null;
    createdAt: string;
  }>;
};

type CompanyWhere = {
  isActive?: boolean;
  OR?: Array<Record<string, unknown>>;
  subscription?: { plan?: { name?: { contains: string; mode: "insensitive" } } };
  billingProfile?: { state?: { contains: string; mode: "insensitive" } };
};

function iso(value: Date | string | null | undefined): string {
  return value ? new Date(value).toISOString() : "";
}

function numberValue(value: unknown): number {
  if (typeof value === "bigint") return Number(value);
  if (typeof value === "number") return value;
  return Number(value ?? 0) || 0;
}

function startOfMonth(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
}

function toRow(
  company: any,
  paymentMap: Map<string, { total: number; plan: number; topup: number }>,
  storageMap: Map<string, number>,
  orderMap: Map<string, number>,
): PlatformCompanyRow {
  const billing = company.billingProfile;
  const subscription = company.subscription;
  const plan = subscription?.plan;
  const payment = paymentMap.get(company.id) ?? { total: 0, plan: 0, topup: 0 };
  const storageUsed = storageMap.get(company.id) ?? 0;
  const orderCount = orderMap.get(company.id) ?? 0;

  const storageQuotaEntitlement = (subscription?.entitlements ?? []).find(
    (e: any) =>
      /storage/i.test(String(e.code ?? "")) &&
      typeof e.valueInt === "number" &&
      String(e.unit ?? "").toUpperCase() === "COUNT",
  );

  return {
    id: String(company.id),
    name: String(company.name ?? "Company"),
    code: company.code == null ? null : String(company.code),
    status: company.isActive ? "ACTIVE" : "INACTIVE",
    userCount: numberValue(company._count?.users),
    activeUserCount: numberValue(company._activeUserCount),
    warehouseCount: numberValue(company._count?.warehouses),
    planName: plan?.name == null ? null : String(plan.name),
    planCode: plan?.code == null ? null : String(plan.code),
    subscriptionStatus:
      subscription?.status == null ? null : String(subscription.status).toUpperCase(),
    createdAt: iso(company.createdAt),
    gstin: billing?.gstin == null ? null : String(billing.gstin),
    billingEmail:
      billing?.billingEmail == null ? null : String(billing.billingEmail),
    billingPhone:
      billing?.billingPhone == null ? null : String(billing.billingPhone),
    address: billing?.addressLine1 == null ? null : String(billing.addressLine1),
    city: billing?.city == null ? null : String(billing.city),
    state: billing?.state == null ? null : String(billing.state),
    country: billing?.country == null ? null : String(billing.country),
    storageUsedBytes: storageUsed,
    storageQuotaBytes:
      storageQuotaEntitlement?.valueInt == null
        ? null
        : numberValue(storageQuotaEntitlement.valueInt),
    orderCountThisMonth: orderCount,
    revenuePaise: payment.total,
    planRevenuePaise: payment.plan,
    topupRevenuePaise: payment.topup,
    planPricePaise: plan?.pricePaise == null ? null : numberValue(plan.pricePaise),
    includedScans: plan?.includedScans == null ? null : numberValue(plan.includedScans),
    maxWarehouses: plan?.maxWarehouses == null ? null : numberValue(plan.maxWarehouses),
    maxOperators: plan?.maxOperators == null ? null : numberValue(plan.maxOperators),
    walletBalance: numberValue(company.scanWallet?.balance),
    walletAllocated: numberValue(company.scanWallet?.lifetimeAllocated),
    walletConsumed: numberValue(company.scanWallet?.lifetimeConsumed),
    recentActivity: [],
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
  }) {
    const limit = Math.min(Math.max(opts.limit ?? 10, 1), 100);
    const page = Math.max(opts.page ?? 1, 1);
    const skip = (page - 1) * limit;
    const search = (opts.search ?? "").trim();
    const plan = (opts.plan ?? "").trim();
    const region = (opts.region ?? "").trim();

    const where: CompanyWhere = {};

    if (opts.status === "active") where.isActive = true;
    if (opts.status === "inactive") where.isActive = false;

    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { code: { contains: search, mode: "insensitive" } },
        {
          billingProfile: {
            billingEmail: { contains: search, mode: "insensitive" },
          },
        },
        {
          billingProfile: {
            gstin: { contains: search, mode: "insensitive" },
          },
        },
      ];
    }

    if (plan) {
      where.subscription = {
        plan: { name: { contains: plan, mode: "insensitive" } },
      };
    }

    if (region) {
      where.billingProfile = {
        state: { contains: region, mode: "insensitive" },
      };
    }

    const [total, activeCompanies, inactiveCompanies, trialCompanies, totalRevenue] =
      await Promise.all([
        prisma.company.count({ where: where as any }),
        prisma.company.count({ where: { ...(where as any), isActive: true } }),
        prisma.company.count({ where: { ...(where as any), isActive: false } }),
        prisma.company.count({
          where: {
            ...(where as any),
            subscription: { ...(where.subscription ?? {}), status: "TRIALING" },
          },
        }),
        prisma.payment.aggregate({
          where: { status: "SUCCESS" },
          _sum: { totalPaise: true },
        }),
      ]);

    const companies = await prisma.company.findMany({
      where: where as any,
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
      include: {
        _count: { select: { users: true, warehouses: true } },
        billingProfile: true,
        subscription: {
          include: {
            plan: true,
            entitlements: true,
          },
        },
        scanWallet: true,
      },
    });

    const ids = companies.map((c) => c.id);

    const [activeUsers, payments, storage, orders] = ids.length
      ? await Promise.all([
          prisma.$queryRawUnsafe<any[]>(
            `SELECT "companyId", COUNT(*)::int AS count
             FROM "users"
             WHERE "companyId" = ANY($1) AND "isActive" = true
             GROUP BY "companyId"`,
            ids,
          ),
          prisma.$queryRawUnsafe<any[]>(
            `WITH paid AS (
               SELECT "companyId", COALESCE(SUM("totalPaise"), 0)::bigint AS total
               FROM "payments"
               WHERE "companyId" = ANY($1) AND status = 'SUCCESS'
               GROUP BY "companyId"
             ),
             items AS (
               SELECT p."companyId",
                      COALESCE(SUM(CASE WHEN pi."itemType" = 'PLAN' THEN pi."totalPaise" ELSE 0 END), 0)::bigint AS plan,
                      COALESCE(SUM(CASE WHEN pi."itemType" = 'EXTRA_SCAN_PACK' THEN pi."totalPaise" ELSE 0 END), 0)::bigint AS topup
               FROM "payments" p
               LEFT JOIN "payment_items" pi ON pi."paymentId" = p.id
               WHERE p."companyId" = ANY($1) AND p.status = 'SUCCESS'
               GROUP BY p."companyId"
             )
             SELECT paid."companyId",
                    paid.total,
                    COALESCE(items.plan, 0)::bigint AS plan,
                    COALESCE(items.topup, 0)::bigint AS topup
             FROM paid
             LEFT JOIN items ON items."companyId" = paid."companyId"`,
            ids,
          ),
          prisma.$queryRawUnsafe<any[]>(
            `SELECT "companyId", COALESCE(SUM("sizeBytes"), 0)::bigint AS "sizeBytes"
             FROM "storage_objects"
             WHERE "companyId" = ANY($1)
             GROUP BY "companyId"`,
            ids,
          ),
          prisma.$queryRawUnsafe<any[]>(
            `SELECT "companyId", COUNT(*)::int AS count
             FROM "orders"
             WHERE "companyId" = ANY($1) AND "createdAt" >= $2
             GROUP BY "companyId"`,
            ids,
            startOfMonth(),
          ),
        ])
      : [[], [], [], []];

    const activeUserMap = new Map(
      (activeUsers as any[]).map((r) => [String(r.companyId), numberValue(r.count)]),
    );

    const paymentMap = new Map<string, { total: number; plan: number; topup: number }>(
      (payments as any[]).map((r) => [
        String(r.companyId),
        {
          total: numberValue(r.total),
          plan: numberValue(r.plan),
          topup: numberValue(r.topup),
        },
      ]),
    );

    const storageMap = new Map(
      (storage as any[]).map((r) => [String(r.companyId), numberValue(r.sizeBytes)]),
    );

    const orderMap = new Map(
      (orders as any[]).map((r) => [String(r.companyId), numberValue(r.count)]),
    );

    const items = companies.map((company: any) => {
      const row = toRow(
        {
          ...company,
          _activeUserCount: activeUserMap.get(company.id) ?? 0,
        },
        paymentMap,
        storageMap,
        orderMap,
      );
      return row;
    });

    return {
      page,
      limit,
      total,
      pages: Math.max(Math.ceil(total / limit), 1),
      summary: {
        totalCompanies: total,
        activeCompanies,
        inactiveCompanies,
        trialCompanies,
        totalRevenuePaise: numberValue(totalRevenue._sum.totalPaise),
      },
      filterOptions: {
        plans: (await prisma.plan.findMany({
          where: { isActive: true },
          select: { name: true },
          orderBy: { sortOrder: "asc" },
        })).map((p) => String(p.name)),
        regions: (await prisma.$queryRawUnsafe<any[]>(
          `SELECT DISTINCT "state" FROM "billing_profiles"
           WHERE "state" IS NOT NULL AND TRIM("state") <> ''
           ORDER BY "state"`,
        )).map((r) => String(r.state)),
      },
      items,
    };
  }

  async get(companyId: string): Promise<PlatformCompanyRow | null> {
    const company = await prisma.company.findUnique({
      where: { id: companyId },
      include: {
        _count: { select: { users: true, warehouses: true } },
        billingProfile: true,
        subscription: {
          include: { plan: true, entitlements: true },
        },
        scanWallet: true,
      },
    });

    if (!company) return null;

    const [activeUsers, payments, storage, orders, activity] = await Promise.all([
      prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*)::int AS count
         FROM "users"
         WHERE "companyId" = $1 AND "isActive" = true`,
        companyId,
      ),
      prisma.$queryRawUnsafe<any[]>(
        `WITH paid AS (
           SELECT COALESCE(SUM("totalPaise"), 0)::bigint AS total
           FROM "payments"
           WHERE "companyId" = $1 AND status = 'SUCCESS'
         ),
         items AS (
           SELECT
             COALESCE(SUM(CASE WHEN pi."itemType" = 'PLAN' THEN pi."totalPaise" ELSE 0 END), 0)::bigint AS plan,
             COALESCE(SUM(CASE WHEN pi."itemType" = 'EXTRA_SCAN_PACK' THEN pi."totalPaise" ELSE 0 END), 0)::bigint AS topup
           FROM "payments" p
           LEFT JOIN "payment_items" pi ON pi."paymentId" = p.id
           WHERE p."companyId" = $1 AND p.status = 'SUCCESS'
         )
         SELECT paid.total, items.plan, items.topup
         FROM paid CROSS JOIN items`,
        companyId,
      ),
      prisma.$queryRawUnsafe<any[]>(
        `SELECT COALESCE(SUM("sizeBytes"), 0)::bigint AS "sizeBytes"
         FROM "storage_objects"
         WHERE "companyId" = $1`,
        companyId,
      ),
      prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*)::int AS count
         FROM "orders"
         WHERE "companyId" = $1 AND "createdAt" >= $2`,
        companyId,
        startOfMonth(),
      ),
      prisma.auditLog.findMany({
        where: { companyId },
        orderBy: { createdAt: "desc" },
        take: 8,
        select: {
          id: true,
          action: true,
          description: true,
          createdAt: true,
          user: { select: { name: true } },
        },
      }),
    ]);

    const paymentRow = (payments as any[])[0] ?? {};
    const payment = {
      total: numberValue(paymentRow.total),
      plan: numberValue(paymentRow.plan),
      topup: numberValue(paymentRow.topup),
    };

    const row = toRow(
      {
        ...company,
        _activeUserCount: numberValue((activeUsers as any[])[0]?.count),
      },
      new Map([[companyId, payment]]),
      new Map([[companyId, numberValue((storage as any[])[0]?.sizeBytes)]]),
      new Map([[companyId, numberValue((orders as any[])[0]?.count)]]),
    );

    row.recentActivity = (activity as any[]).map((a) => ({
      id: String(a.id),
      action: String(a.action ?? ""),
      description: a.description == null ? null : String(a.description),
      userName: a.user?.name == null ? null : String(a.user.name),
      createdAt: iso(a.createdAt),
    }));

    return row;
  }

  async setActive(companyId: string, isActive: boolean) {
    const existing = await prisma.company.findUnique({
      where: { id: companyId },
      select: { id: true },
    });

    if (!existing) throw new Error("COMPANY_NOT_FOUND");

    const updated = await prisma.company.update({
      where: { id: companyId },
      data: { isActive },
      select: { id: true, isActive: true },
    });

    return {
      id: updated.id,
      isActive: updated.isActive,
      status: updated.isActive ? "ACTIVE" : "INACTIVE",
    };
  }
}
'@

$backendControllerContent = @'
import type { Response } from "express";
import { routeParam } from "./route-param.js";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { IdentityService } from "../../services/identity/identity.service.js";
import { PlatformCompaniesService } from "../../services/platform/platform-companies.service.js";

const identityService = new IdentityService();
const companiesService = new PlatformCompaniesService();

function isPlatformAdmin(role: unknown): boolean {
  const r = String(role ?? "").toUpperCase().replace(/-/g, "_");
  return r === "PLATFORM_ADMIN" || r === "SUPER_ADMIN";
}

async function requirePlatformAdmin(
  req: AuthenticatedRequest,
  res: Response,
) {
  const uid = req.firebaseUser?.uid;
  if (!uid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return null;
  }

  const user = await identityService.getByFirebaseUid(uid);
  if (!user || !isPlatformAdmin(user.role)) {
    res.status(403).json({
      success: false,
      code: "FORBIDDEN",
      message: "Platform administrator access required.",
    });
    return null;
  }

  return user;
}

export async function listPlatformCompanies(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const search =
      typeof req.query.search === "string" ? req.query.search : "";
    const statusRaw =
      typeof req.query.status === "string" ? req.query.status : "all";
    const status =
      statusRaw === "active" || statusRaw === "inactive"
        ? statusRaw
        : "all";

    const plan = typeof req.query.plan === "string" ? req.query.plan : "";
    const region =
      typeof req.query.region === "string" ? req.query.region : "";

    const page = Math.max(Number(req.query.page ?? 1) || 1, 1);
    const limit = Math.min(
      Math.max(Number(req.query.limit ?? 10) || 10, 1),
      100,
    );

    const result = await companiesService.list({
      search,
      status,
      plan,
      region,
      page,
      limit,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error(
      "listPlatformCompanies failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to load companies.",
    });
  }
}

export async function getPlatformCompany(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const companyId = routeParam(req.params.id).trim();
    if (!companyId) {
      res.status(400).json({
        success: false,
        message: "Company id required.",
      });
      return;
    }

    const result = await companiesService.get(companyId);

    if (!result) {
      res.status(404).json({
        success: false,
        message: "Company not found.",
      });
      return;
    }

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error(
      "getPlatformCompany failed:",
      error instanceof Error ? error.stack : error,
    );
    res.status(500).json({
      success: false,
      message: "Unable to load company.",
    });
  }
}

export async function setCompanyActive(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;

    const companyId = routeParam(req.params.id).trim();
    if (!companyId) {
      res.status(400).json({
        success: false,
        message: "Company id required.",
      });
      return;
    }

    const isActive = req.body?.isActive;
    if (typeof isActive !== "boolean") {
      res.status(400).json({
        success: false,
        message: "isActive boolean is required.",
      });
      return;
    }

    const updated = await companiesService.setActive(companyId, isActive);

    res.json({
      success: true,
      data: updated,
    });
  } catch (error) {
    console.error(
      "setCompanyActive failed:",
      error instanceof Error ? error.stack : error,
    );

    const message =
      error instanceof Error && error.message === "COMPANY_NOT_FOUND"
        ? "Company not found."
        : "Unable to update company.";

    res.status(message === "Company not found." ? 404 : 500).json({
      success: false,
      message,
    });
  }
}
'@

$backendRoutesContent = @'
import { Router } from "express";
import {
  getPlatformCompany,
  listPlatformCompanies,
  setCompanyActive,
} from "../controllers/platform/companies.controller.js";

const router = Router();

router.get("/", listPlatformCompanies);
router.get("/:id", getPlatformCompany);
router.patch("/:id/status", setCompanyActive);

export default router;
'@

$frontendServiceContent = @'
import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformCompany {
  final String id;
  final String name;
  final String? code;
  final String status;
  final int userCount;
  final int activeUserCount;
  final int warehouseCount;
  final String? planName;
  final String? planCode;
  final String? subscriptionStatus;
  final String createdAt;
  final String? gstin;
  final String? billingEmail;
  final String? billingPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final int storageUsedBytes;
  final int? storageQuotaBytes;
  final int orderCountThisMonth;
  final int revenuePaise;
  final int planRevenuePaise;
  final int topupRevenuePaise;
  final int? planPricePaise;
  final int? includedScans;
  final int? maxWarehouses;
  final int? maxOperators;
  final int walletBalance;
  final int walletAllocated;
  final int walletConsumed;
  final List<PlatformCompanyActivity> recentActivity;

  const PlatformCompany({
    required this.id,
    required this.name,
    this.code,
    required this.status,
    required this.userCount,
    required this.activeUserCount,
    required this.warehouseCount,
    this.planName,
    this.planCode,
    this.subscriptionStatus,
    required this.createdAt,
    this.gstin,
    this.billingEmail,
    this.billingPhone,
    this.address,
    this.city,
    this.state,
    this.country,
    required this.storageUsedBytes,
    this.storageQuotaBytes,
    required this.orderCountThisMonth,
    required this.revenuePaise,
    required this.planRevenuePaise,
    required this.topupRevenuePaise,
    this.planPricePaise,
    this.includedScans,
    this.maxWarehouses,
    this.maxOperators,
    required this.walletBalance,
    required this.walletAllocated,
    required this.walletConsumed,
    required this.recentActivity,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  String get region => state?.trim().isNotEmpty == true ? state! : 'All';

  factory PlatformCompany.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    int? nullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    final rawActivity = json['recentActivity'];

    return PlatformCompany(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Company',
      code: json['code']?.toString(),
      status: json['status']?.toString() ?? 'INACTIVE',
      userCount: n(json['userCount']),
      activeUserCount: n(json['activeUserCount']),
      warehouseCount: n(json['warehouseCount']),
      planName: json['planName']?.toString(),
      planCode: json['planCode']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      gstin: json['gstin']?.toString(),
      billingEmail: json['billingEmail']?.toString(),
      billingPhone: json['billingPhone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      storageUsedBytes: n(json['storageUsedBytes']),
      storageQuotaBytes: nullableInt(json['storageQuotaBytes']),
      orderCountThisMonth: n(json['orderCountThisMonth']),
      revenuePaise: n(json['revenuePaise']),
      planRevenuePaise: n(json['planRevenuePaise']),
      topupRevenuePaise: n(json['topupRevenuePaise']),
      planPricePaise: nullableInt(json['planPricePaise']),
      includedScans: nullableInt(json['includedScans']),
      maxWarehouses: nullableInt(json['maxWarehouses']),
      maxOperators: nullableInt(json['maxOperators']),
      walletBalance: n(json['walletBalance']),
      walletAllocated: n(json['walletAllocated']),
      walletConsumed: n(json['walletConsumed']),
      recentActivity: rawActivity is List
          ? rawActivity
              .whereType<Map>()
              .map(
                (e) => PlatformCompanyActivity.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class PlatformCompanyActivity {
  final String id;
  final String action;
  final String? description;
  final String? userName;
  final String createdAt;

  const PlatformCompanyActivity({
    required this.id,
    required this.action,
    this.description,
    this.userName,
    required this.createdAt,
  });

  factory PlatformCompanyActivity.fromJson(Map<String, dynamic> json) {
    return PlatformCompanyActivity(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString(),
      userName: json['userName']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformCompaniesSummary {
  final int totalCompanies;
  final int activeCompanies;
  final int inactiveCompanies;
  final int trialCompanies;
  final int totalRevenuePaise;

  const PlatformCompaniesSummary({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.inactiveCompanies,
    required this.trialCompanies,
    required this.totalRevenuePaise,
  });

  factory PlatformCompaniesSummary.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformCompaniesSummary(
      totalCompanies: n(json['totalCompanies']),
      activeCompanies: n(json['activeCompanies']),
      inactiveCompanies: n(json['inactiveCompanies']),
      trialCompanies: n(json['trialCompanies']),
      totalRevenuePaise: n(json['totalRevenuePaise']),
    );
  }
}

class PlatformCompaniesPage {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final PlatformCompaniesSummary summary;
  final List<String> plans;
  final List<String> regions;
  final List<PlatformCompany> items;

  const PlatformCompaniesPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.summary,
    required this.plans,
    required this.regions,
    required this.items,
  });

  factory PlatformCompaniesPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawSummary = json['summary'];

    return PlatformCompaniesPage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
      summary: PlatformCompaniesSummary.fromJson(
        rawSummary is Map
            ? Map<String, dynamic>.from(rawSummary)
            : const <String, dynamic>{},
      ),
      plans: (json['filterOptions'] is Map &&
              (json['filterOptions'] as Map)['plans'] is List)
          ? ((json['filterOptions'] as Map)['plans'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      regions: (json['filterOptions'] is Map &&
              (json['filterOptions'] as Map)['regions'] is List)
          ? ((json['filterOptions'] as Map)['regions'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => PlatformCompany.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class PlatformCompaniesService {
  final ApiClient _client;

  const PlatformCompaniesService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<PlatformCompaniesPage> list({
    String search = '',
    String status = 'all',
    String plan = '',
    String region = '',
    int page = 1,
    int limit = 10,
  }) async {
    final qs = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != 'all') 'status': status,
      if (plan.trim().isNotEmpty && plan != 'All') 'plan': plan.trim(),
      if (region.trim().isNotEmpty && region != 'All') 'region': region.trim(),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/companies')
        .replace(queryParameters: qs);

    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load companies.');
    }

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception('Invalid companies response.');
    }

    return PlatformCompaniesPage.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<PlatformCompany> get(String id) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id'),
    );
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load company.');
    }

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception('Invalid company response.');
    }

    return PlatformCompany.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<void> setActive(String id, bool isActive) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id/status'),
      body: {'isActive': isActive},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to update company.');
    }
  }
}
'@

$frontendScreenContent = @'
import 'package:flutter/material.dart';

import '../../services/platform/platform_companies_service.dart';

class PlatformCompaniesScreen extends StatefulWidget {
  const PlatformCompaniesScreen({super.key});

  @override
  State<PlatformCompaniesScreen> createState() =>
      _PlatformCompaniesScreenState();
}

class _PlatformCompaniesScreenState extends State<PlatformCompaniesScreen> {
  static const _navy = Color(0xFF10235E);
  static const _blue = Color(0xFF1769FF);
  static const _green = Color(0xFF0DBB78);
  static const _orange = Color(0xFFFF9819);
  static const _red = Color(0xFFF23D4F);
  static const _purple = Color(0xFF8A35F5);
  static const _background = Color(0xFFF7F9FC);
  static const _border = Color(0xFFE1E7F0);
  static const _muted = Color(0xFF6F7D9E);
  static const _text = Color(0xFF10235E);

  final _service = const PlatformCompaniesService();
  final _searchController = TextEditingController();

  PlatformCompaniesPage? _page;
  PlatformCompany? _selected;
  Object? _error;

  String _status = 'all';
  String _plan = 'All';
  String _region = 'All';
  int _pageNumber = 1;

  bool _loading = true;
  bool _detailLoading = false;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool keepSelection = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.list(
        search: _searchController.text,
        status: _status,
        plan: _plan,
        region: _region,
        page: _pageNumber,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _page = result;
        _loading = false;
      });

      if (result.items.isEmpty) {
        setState(() => _selected = null);
        return;
      }

      final existingId = keepSelection ? _selected?.id : null;
      final row = result.items.firstWhere(
        (item) => item.id == existingId,
        orElse: () => result.items.first,
      );

      await _loadDetail(row.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadDetail(String id) async {
    setState(() => _detailLoading = true);

    try {
      final company = await _service.get(id);
      if (!mounted) return;

      setState(() {
        _selected = company;
        _detailLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final fallback = _page?.items.where((item) => item.id == id);
      setState(() {
        _selected = fallback != null && fallback.isNotEmpty
            ? fallback.first
            : null;
        _detailLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _toggleCompany() async {
    final company = _selected;
    if (company == null || _updatingStatus) return;

    setState(() => _updatingStatus = true);

    try {
      await _service.setActive(company.id, !company.isActive);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            company.isActive
                ? '${company.name} suspended'
                : '${company.name} activated',
          ),
        ),
      );

      await _load(keepSelection: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: Column(
        children: [
          _pageHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : _error != null
                    ? _errorView()
                    : _content(),
          ),
        ],
      ),
    );
  }

  Widget _pageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: const [
                    Text(
                      'Platform Admin',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 15, color: _muted),
                    Text(
                      'Companies',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Companies Management',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage all onboarded companies, their subscriptions, usage and activity.',
                            style: TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Company creation flow is not connected yet.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Company'),
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final page = _page;

    if (page == null || page.items.isEmpty) {
      return _emptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1180;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _leftContent(page),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 390,
                      child: _detailPanel(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _leftContent(page),
                    const SizedBox(height: 12),
                    _detailPanel(),
                  ],
                ),
        );
      },
    );
  }

  Widget _leftContent(PlatformCompaniesPage page) {
    return Column(
      children: [
        _summaryCards(page.summary),
        const SizedBox(height: 12),
        _filters(page),
        const SizedBox(height: 10),
        _table(page),
      ],
    );
  }

  Widget _summaryCards(PlatformCompaniesSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 30) / 4;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                title: 'Total Companies',
                value: _number(summary.totalCompanies),
                icon: Icons.business_rounded,
                color: _blue,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                title: 'Active Companies',
                value: _number(summary.activeCompanies),
                icon: Icons.groups_rounded,
                color: _purple,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                title: 'Trial Companies',
                value: _number(summary.trialCompanies),
                icon: Icons.pause_circle_outline_rounded,
                color: _red,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                title: 'Revenue',
                value: _money(summary.totalRevenuePaise),
                icon: Icons.currency_rupee_rounded,
                color: _green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filters(PlatformCompaniesPage page) {
    return _Surface(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 290,
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) {
                _pageNumber = 1;
                _load(keepSelection: false);
              },
              decoration: InputDecoration(
                hintText: 'Search by company name, email or GST...',
                prefixIcon: const Icon(Icons.search, size: 19),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFAFCFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
            ),
          ),
          _filterDropdown(
            label: 'Status',
            value: _status == 'all' ? 'All Statuses' : _status.toUpperCase(),
            items: const ['All Statuses', 'ACTIVE', 'INACTIVE'],
            onChanged: (value) {
              _status = value == 'All Statuses' ? 'all' : value.toLowerCase();
              _pageNumber = 1;
              _load(keepSelection: false);
            },
          ),
          _filterDropdown(
            label: 'Plan',
            value: _plan,
            items: ['All', ...page.plans],
            onChanged: (value) {
              _plan = value;
              _pageNumber = 1;
              _load(keepSelection: false);
            },
          ),
          _filterDropdown(
            label: 'Region',
            value: _region,
            items: ['All', ...page.regions],
            onChanged: (value) {
              _region = value;
              _pageNumber = 1;
              _load(keepSelection: false);
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _load(keepSelection: true),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Refresh'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export is not connected yet.'),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 17),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  Widget _table(PlatformCompaniesPage page) {
    final start = page.total == 0 ? 0 : ((page.page - 1) * page.limit) + 1;
    final end = ((page.page - 1) * page.limit + page.items.length)
        .clamp(0, page.total);

    return _Surface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  'Showing $start–$end of ${page.total} companies',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _pager(page),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              horizontalMargin: 12,
              headingRowHeight: 38,
              dataRowMinHeight: 58,
              dataRowMaxHeight: 64,
              headingRowColor:
                  const WidgetStatePropertyAll(Color(0xFFF9FBFE)),
              columns: const [
                DataColumn(label: Text('Company')),
                DataColumn(label: Text('Plan')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Users')),
                DataColumn(label: Text('Warehouses')),
                DataColumn(label: Text('Storage Usage')),
                DataColumn(label: Text('Revenue')),
                DataColumn(label: Text('Joined Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows: page.items.map(_companyRow).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _companyRow(PlatformCompany company) {
    final selected = _selected?.id == company.id;

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => selected ? const Color(0xFFF1F6FF) : null,
      ),
      cells: [
        DataCell(
          InkWell(
            onTap: () => _loadDetail(company.id),
            child: SizedBox(
              width: 180,
              child: Row(
                children: [
                  _companyAvatar(company.name),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (company.gstin != null ||
                            company.code != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            company.gstin ?? 'ID: ${company.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(_pill(company.planName ?? 'No plan', _purple)),
        DataCell(
          _pill(
            company.subscriptionStatus ?? company.status,
            company.isActive ? _green : _red,
          ),
        ),
        DataCell(Text('${company.userCount}')),
        DataCell(Text('${company.warehouseCount}')),
        DataCell(_storageCell(company)),
        DataCell(
          Text(
            _money(company.revenuePaise),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        DataCell(Text(_date(company.createdAt))),
        DataCell(
          IconButton(
            tooltip: 'Open company',
            onPressed: () => _loadDetail(company.id),
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _storageCell(PlatformCompany company) {
    final quota = company.storageQuotaBytes;

    if (quota == null || quota <= 0) {
      return Text(
        _bytes(company.storageUsedBytes),
        style: const TextStyle(fontSize: 10),
      );
    }

    final progress =
        (company.storageUsedBytes / quota).clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE8EDF5),
                    valueColor: AlwaysStoppedAnimation(
                      progress >= .8 ? _red : _blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 9, color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${_bytes(company.storageUsedBytes)} / ${_bytes(quota)}',
            style: const TextStyle(fontSize: 8.5, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _pager(PlatformCompaniesPage page) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: page.page > 1
              ? () {
                  _pageNumber = page.page - 1;
                  _load(keepSelection: false);
                }
              : null,
          icon: const Icon(Icons.chevron_left_rounded, size: 19),
        ),
        Text(
          '${page.page} / ${page.pages}',
          style: const TextStyle(
            color: _navy,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: page.page < page.pages
              ? () {
                  _pageNumber = page.page + 1;
                  _load(keepSelection: false);
                }
              : null,
          icon: const Icon(Icons.chevron_right_rounded, size: 19),
        ),
      ],
    );
  }

  Widget _detailPanel() {
    final company = _selected;

    return _Surface(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: _detailLoading && company == null
          ? const SizedBox(
              height: 520,
              child: Center(
                child: CircularProgressIndicator(color: _blue),
              ),
            )
          : company == null
              ? const SizedBox(
                  height: 420,
                  child: Center(
                    child: Text(
                      'Select a company',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _companyAvatar(company.name, size: 38),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                company.gstin == null
                                    ? company.code ?? 'Company'
                                    : 'GST: ${company.gstin}',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _pill(
                          company.isActive ? 'Active' : 'Inactive',
                          company.isActive ? _green : _red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: _border),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _miniStat(
                          'Users',
                          '${company.activeUserCount}',
                          'Active users',
                          Icons.people_alt_outlined,
                          _blue,
                        ),
                        const SizedBox(width: 7),
                        _miniStat(
                          'Warehouses',
                          '${company.warehouseCount}',
                          'Total warehouses',
                          Icons.warehouse_outlined,
                          _purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _miniStat(
                          'Orders',
                          _number(company.orderCountThisMonth),
                          'This month',
                          Icons.inventory_2_outlined,
                          _green,
                        ),
                        const SizedBox(width: 7),
                        _miniStat(
                          'Storage',
                          _bytes(company.storageUsedBytes),
                          company.storageQuotaBytes == null
                              ? 'Used'
                              : 'of ${_bytes(company.storageQuotaBytes!)}',
                          Icons.storage_outlined,
                          _orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('Company Information', action: _toggleButton(company)),
                    const SizedBox(height: 8),
                    _infoGrid(company),
                    const SizedBox(height: 15),
                    _sectionTitle('Revenue Overview'),
                    const SizedBox(height: 8),
                    _revenueCard(company),
                    const SizedBox(height: 15),
                    _sectionTitle('Usage & Limits'),
                    const SizedBox(height: 8),
                    _usagePanel(company),
                    const SizedBox(height: 15),
                    _sectionTitle('Recent Activity'),
                    const SizedBox(height: 8),
                    ...company.recentActivity.take(6).map(_activityRow),
                  ],
                ),
    );
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _toggleButton(PlatformCompany company) {
    return OutlinedButton(
      onPressed: _updatingStatus ? null : _toggleCompany,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(company.isActive ? 'Suspend' : 'Activate'),
    );
  }

  Widget _infoGrid(PlatformCompany company) {
    final address = [
      company.address,
      company.city,
      company.state,
      company.country,
    ].where((value) => value?.trim().isNotEmpty == true).join(', ');

    return Column(
      children: [
        _infoRow('Company Name', company.name),
        _infoRow('GST Number', company.gstin ?? '—'),
        _infoRow('Email', company.billingEmail ?? '—'),
        _infoRow('Phone', company.billingPhone ?? '—'),
        _infoRow('Address', address.isEmpty ? '—' : address),
        _infoRow('Joined Date', _date(company.createdAt)),
        _infoRow('Plan', company.planName ?? '—'),
        _infoRow(
          'Subscription',
          company.subscriptionStatus ?? '—',
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 9),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _navy,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueCard(PlatformCompany company) {
    final total = company.revenuePaise;
    final plan = company.planRevenuePaise;
    final topup = company.topupRevenuePaise;

    final planRatio = total <= 0 ? 0.0 : (plan / total).clamp(0.0, 1.0);
    final topupRatio = total <= 0 ? 0.0 : (topup / total).clamp(0.0, 1.0);

    return _Surface(
      color: const Color(0xFFFAFCFF),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Revenue',
            style: TextStyle(color: _muted, fontSize: 9.5),
          ),
          const SizedBox(height: 3),
          Text(
            _money(total),
            style: const TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (planRatio > 0)
                    Expanded(
                      flex: (planRatio * 1000).round().clamp(1, 1000),
                      child: Container(color: _blue),
                    ),
                  if (topupRatio > 0)
                    Expanded(
                      flex: (topupRatio * 1000).round().clamp(1, 1000),
                      child: Container(color: _orange),
                    ),
                  if (total <= 0)
                    Expanded(child: Container(color: _border)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              _legend(_blue, 'Plan Revenue', _money(plan)),
              const Spacer(),
              _legend(_orange, 'Top-ups', _money(topup)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _usagePanel(PlatformCompany company) {
    final widgets = <Widget>[
      _usageBar(
        label: 'Storage Usage',
        used: _bytes(company.storageUsedBytes),
        total: company.storageQuotaBytes == null
            ? 'Quota not configured'
            : _bytes(company.storageQuotaBytes!),
        progress: company.storageQuotaBytes == null
            ? null
            : company.storageUsedBytes /
                company.storageQuotaBytes!.clamp(1, 1 << 62),
        color: _blue,
      ),
      _usageBar(
        label: 'Scan Activity',
        used: _number(company.orderCountThisMonth),
        total: company.includedScans == null
            ? 'Plan limit not configured'
            : _number(company.includedScans!),
        progress: company.includedScans == null
            ? null
            : company.orderCountThisMonth /
                company.includedScans!.clamp(1, 1 << 62),
        color: _green,
      ),
      _usageBar(
        label: 'Active Users',
        used: _number(company.activeUserCount),
        total: company.maxOperators == null
            ? 'Operator limit not configured'
            : _number(company.maxOperators!),
        progress: company.maxOperators == null
            ? null
            : company.activeUserCount /
                company.maxOperators!.clamp(1, 1 << 62),
        color: _purple,
      ),
    ];

    return _Surface(
      color: const Color(0xFFFAFCFF),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (var i = 0; i < widgets.length; i++) ...[
            widgets[i],
            if (i != widgets.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _border),
              ),
          ],
        ],
      ),
    );
  }

  Widget _usageBar({
    required String label,
    required String used,
    required String total,
    required double? progress,
    required Color color,
  }) {
    final safeProgress =
        progress == null ? null : progress.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$used / $total',
              style: const TextStyle(color: _muted, fontSize: 8.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: safeProgress,
            minHeight: 7,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _activityRow(PlatformCompanyActivity activity) {
    final action = activity.action.replaceAll('_', ' ');
    final subtitle = activity.description?.trim().isNotEmpty == true
        ? activity.description!
        : activity.userName ?? 'Platform activity';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleCase(action),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 8.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(activity.createdAt),
            style: const TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(color: _muted, fontSize: 8.5),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 7.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label  ',
          style: const TextStyle(color: _muted, fontSize: 8.5),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _companyAvatar(String name, {double size = 32}) {
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();
    final colors = <Color>[_blue, _purple, _green, _orange, _red];
    final color = colors[name.hashCode.abs() % colors.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontSize: size * .42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: _Surface(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: _muted, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Unable to load companies',
              style: TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 430,
              child: Text(
                'The screen is using the live Platform Admin API. No fallback company data is shown.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 10.5),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: _Surface(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined, color: _muted, size: 42),
            const SizedBox(height: 10),
            const Text(
              'No companies found',
              style: TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Try changing the search or filters.',
              style: TextStyle(color: _muted, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    Color color = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _MetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _Surface(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _number(int value) {
    final raw = value.abs().toString();
    if (raw.length <= 3) return value.toString();

    final last = raw.substring(raw.length - 3);
    var prefix = raw.substring(0, raw.length - 3);
    final parts = <String>[];

    while (prefix.length > 2) {
      parts.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    if (prefix.isNotEmpty) parts.insert(0, prefix);

    final formatted = '${parts.join(',')},$last';
    return value < 0 ? '-$formatted' : formatted;
  }

  String _money(int paise) {
    final rupees = paise / 100;
    if (rupees == rupees.roundToDouble()) {
      return '₹${_number(rupees.toInt())}';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  String _bytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;
    const tb = gb * 1024;

    if (bytes >= tb) return '${(bytes / tb).toStringAsFixed(2)} TB';
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  String _date(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '—';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  String _relativeTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '—';

    final difference = DateTime.now().toUtc().difference(parsed.toUtc());

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 30) return '${difference.inDays}d ago';

    return _date(raw);
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
'@

[System.IO.File]::WriteAllText($backendService, $backendServiceContent, $utf8)
[System.IO.File]::WriteAllText($backendController, $backendControllerContent, $utf8)
[System.IO.File]::WriteAllText($backendRoutes, $backendRoutesContent, $utf8)
[System.IO.File]::WriteAllText($frontendService, $frontendServiceContent, $utf8)
[System.IO.File]::WriteAllText($frontendScreen, $frontendScreenContent, $utf8)

Write-Host "Companies Management live-data implementation written." -ForegroundColor Green
Write-Host "Next: backend build + flutter analyze." -ForegroundColor Cyan
