import { prisma } from "../../config/prisma.js";

export class PlatformSubscriptionsService {
  async list(opts: { search?: string; status?: string; limit?: number }) {
    const limit = Math.min(Math.max(opts.limit ?? 100, 1), 200);
    const attempts = [
      `SELECT bs.id, bs."companyId", c."companyName" AS "companyName", bs.plan::text AS "planCode",
        pc.name AS "planName", bs.status::text AS status, bs."razorpaySubId", pc."pricePaise",
        pc.currency, pc."billingInterval", pc."includedScans", bs."currentPeriodStart",
        bs."currentPeriodEnd", bs."createdAt"
       FROM "BillingSubscription" bs
       LEFT JOIN "Company" c ON c.id = bs."companyId"
       LEFT JOIN plan_configurations pc ON LOWER(pc.code) = LOWER(bs.plan::text)
       ORDER BY bs."createdAt" DESC NULLS LAST LIMIT ${limit}`,
      `SELECT bs.id, bs."companyId", c."companyName" AS "companyName", bs.plan::text AS "planCode",
        NULL AS "planName", bs.status::text AS status, bs."razorpaySubId", NULL::int AS "pricePaise",
        NULL AS currency, NULL AS "billingInterval", NULL::int AS "includedScans",
        bs."currentPeriodStart", bs."currentPeriodEnd", bs."createdAt"
       FROM "BillingSubscription" bs LEFT JOIN "Company" c ON c.id = bs."companyId"
       ORDER BY bs."createdAt" DESC NULLS LAST LIMIT ${limit}`,
      `SELECT bs.id, bs."companyId", NULL AS "companyName", bs.plan::text AS "planCode",
        NULL AS "planName", bs.status::text AS status, NULL AS "razorpaySubId",
        NULL::int AS "pricePaise", NULL AS currency, NULL AS "billingInterval", NULL::int AS "includedScans",
        NULL AS "currentPeriodStart", NULL AS "currentPeriodEnd", bs."createdAt"
       FROM "BillingSubscription" bs ORDER BY bs."createdAt" DESC NULLS LAST LIMIT ${limit}`,
    ];
    let rows: any[] | null = null;
    for (const sql of attempts) {
      try { rows = await prisma.$queryRawUnsafe<any[]>(sql); break; }
      catch (e) { console.warn("[subscriptions] attempt", e); }
    }
    if (!rows) return { total: 0, items: [] as any[] };

    let items = rows.map((r) => ({
      id: String(r.id), companyId: String(r.companyId ?? ""),
      companyName: r.companyName != null ? String(r.companyName) : null,
      planCode: r.planCode != null ? String(r.planCode) : null,
      planName: r.planName != null ? String(r.planName) : null,
      status: String(r.status ?? "UNKNOWN").toUpperCase(),
      razorpaySubId: r.razorpaySubId != null ? String(r.razorpaySubId) : null,
      pricePaise: r.pricePaise != null ? Number(r.pricePaise) : null,
      currency: r.currency != null ? String(r.currency) : null,
      billingInterval: r.billingInterval != null ? String(r.billingInterval) : null,
      includedScans: r.includedScans != null ? Number(r.includedScans) : null,
      currentPeriodStart: r.currentPeriodStart ? new Date(r.currentPeriodStart).toISOString() : null,
      currentPeriodEnd: r.currentPeriodEnd ? new Date(r.currentPeriodEnd).toISOString() : null,
      createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
    }));
    if (opts.status && opts.status !== "all") {
      const sf = opts.status.toUpperCase();
      items = items.filter((i) => i.status === sf);
    }
    if (opts.search?.trim()) {
      const q = opts.search.trim().toLowerCase();
      items = items.filter((i) =>
        (i.companyName ?? "").toLowerCase().includes(q) ||
        (i.planCode ?? "").toLowerCase().includes(q) ||
        (i.planName ?? "").toLowerCase().includes(q));
    }
    return { total: items.length, items };
  }
}
