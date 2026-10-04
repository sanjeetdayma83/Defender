import { prisma } from "../../config/prisma.js";

export class PlatformTopupsService {
  async list() {
    for (const sql of [
      `SELECT id, code, name, description, credits AS credits, "pricePaise", currency, "isActive", "createdAt" FROM scan_topup_packs ORDER BY "pricePaise" ASC NULLS LAST LIMIT 100`,
      `SELECT id, code, name, description, "scanCredits" AS credits, "pricePaise", currency, "isActive", "createdAt" FROM extra_scan_packs ORDER BY "pricePaise" ASC NULLS LAST LIMIT 100`,
    ]) {
      try {
        const rows = await prisma.$queryRawUnsafe<any[]>(sql);
        return { total: rows.length, items: rows.map(mapPack) };
      } catch (e) { console.warn("[topups]", e); }
    }
    return { total: 0, items: [] as any[] };
  }
  async create(body: any) {
    const code = String(body.code ?? "").trim().toLowerCase();
    const name = String(body.name ?? "").trim();
    const credits = Number(body.credits ?? body.scanCredits ?? 0);
    const pricePaise = Number(body.pricePaise ?? 0);
    if (!code || !name) throw new Error("code and name required");
    try {
      const rows = await prisma.$queryRawUnsafe<any[]>(
        `INSERT INTO extra_scan_packs (id,code,name,description,"scanCredits","pricePaise",currency,"isActive","createdAt","updatedAt")
         VALUES (gen_random_uuid()::text,$1,$2,$3,$4,$5,$6,true,NOW(),NOW()) RETURNING *`,
        code, name, body.description ?? null, credits, pricePaise, body.currency ?? "INR");
      return mapPack({ ...rows[0], credits: rows[0].scanCredits ?? rows[0].credits });
    } catch (e) {
      const rows = await prisma.$queryRawUnsafe<any[]>(
        `INSERT INTO scan_topup_packs (id,code,name,description,credits,"pricePaise",currency,"isActive","createdAt","updatedAt")
         VALUES (gen_random_uuid()::text,$1,$2,$3,$4,$5,$6,true,NOW(),NOW()) RETURNING *`,
        code, name, body.description ?? null, credits, pricePaise, body.currency ?? "INR");
      return mapPack(rows[0]);
    }
  }
  async setActive(id: string, isActive: boolean) {
    for (const t of ["extra_scan_packs", "scan_topup_packs"]) {
      try {
        await prisma.$executeRawUnsafe(`UPDATE ${t} SET "isActive"=$2,"updatedAt"=NOW() WHERE id=$1`, id, isActive);
        return { id, isActive };
      } catch {}
    }
    return { id, isActive };
  }
}
function mapPack(r: any) {
  return {
    id: String(r.id), code: String(r.code ?? ""), name: String(r.name ?? ""),
    description: r.description != null ? String(r.description) : null,
    credits: Number(r.credits ?? r.scanCredits ?? 0), pricePaise: Number(r.pricePaise ?? 0),
    currency: String(r.currency ?? "INR"), isActive: Boolean(r.isActive ?? true),
    createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
  };
}

function mapStorageRows(rows: any[]) {
  return (rows ?? []).map((r) => ({
    companyId: String(r.companyId),
    companyName: r.companyName != null ? String(r.companyName) : null,
    usedBytes: Number(r.usedBytes ?? 0),
    objectCount: Number(r.objectCount ?? 0),
  }));
}

export class PlatformOpsService {
  async storageOverview() {
    const tries = [
      `SELECT c.id AS "companyId", c."companyName" AS "companyName",
        COALESCE(SUM(so."sizeBytes"),0)::bigint AS "usedBytes", COUNT(so.id)::int AS "objectCount"
       FROM "Company" c LEFT JOIN storage_objects so ON so."companyId"=c.id
       GROUP BY c.id, c."companyName" ORDER BY "usedBytes" DESC LIMIT 200`,
      `SELECT c.id AS "companyId", c."companyName" AS "companyName",
        COALESCE(SUM(so."sizeBytes"),0)::bigint AS "usedBytes", COUNT(so.id)::int AS "objectCount"
       FROM "Company" c LEFT JOIN "StorageObject" so ON so."companyId"=c.id
       GROUP BY c.id, c."companyName" ORDER BY "usedBytes" DESC LIMIT 200`,
      `SELECT c.id AS "companyId", c."companyName" AS "companyName",
        COALESCE(SUM(em."sizeBytes"),0)::bigint AS "usedBytes", COUNT(em.id)::int AS "objectCount"
       FROM "Company" c
       LEFT JOIN "Order" o ON o."companyId"=c.id
       LEFT JOIN "PackingSession" ps ON ps."orderId"=o.id
       LEFT JOIN "EvidenceMedia" em ON em."packingSessionId"=ps.id
       GROUP BY c.id, c."companyName" ORDER BY "usedBytes" DESC LIMIT 200`,
      `SELECT c.id AS "companyId", c."companyName" AS "companyName",
        0::bigint AS "usedBytes", 0::int AS "objectCount"
       FROM "Company" c ORDER BY c."companyName" ASC LIMIT 200`,
    ];
    for (const sql of tries) {
      try {
        const rows = await prisma.$queryRawUnsafe<any[]>(sql);
        const items = mapStorageRows(rows);
        const totalBytes = items.reduce((a, b) => a + b.usedBytes, 0);
        return { totalBytes, items };
      } catch (e) { console.warn("[storage]", e); }
    }
    return { totalBytes: 0, items: [] as any[] };
  }

  async analyticsSummary() {
    const safe = async (sql: string) => {
      try { return Number((await prisma.$queryRawUnsafe<any[]>(sql))?.[0]?.c ?? 0); }
      catch { return 0; }
    };
    return {
      companies: await safe(`SELECT COUNT(*)::int AS c FROM "Company"`),
      users: await safe(`SELECT COUNT(*)::int AS c FROM "User"`),
      activeSubscriptions: await safe(
        `SELECT COUNT(*)::int AS c FROM "BillingSubscription" WHERE status::text ILIKE '%active%'`),
      generatedAt: new Date().toISOString(),
    };
  }

  async auditLogs(limit = 100) {
    const lim = Math.min(Math.max(limit, 1), 200);
    for (const sql of [
      `SELECT id, action::text AS action, "createdAt" FROM "AuditLog" ORDER BY "createdAt" DESC LIMIT ${lim}`,
      `SELECT id, action::text AS action, "createdAt" FROM audit_logs ORDER BY "createdAt" DESC LIMIT ${lim}`,
    ]) {
      try {
        const rows = await prisma.$queryRawUnsafe<any[]>(sql);
        return {
          total: rows.length,
          items: rows.map((r) => ({
            id: String(r.id), companyId: null, userId: null,
            action: String(r.action ?? ""), entity: null, entityId: null, metadata: null,
            createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
          })),
        };
      } catch (e) { console.warn("[audit]", e); }
    }
    return { total: 0, items: [] as any[] };
  }

  async getSettings() {
    try {
      const rows = await prisma.$queryRawUnsafe<any[]>(`SELECT key, value::text AS value FROM platform_settings ORDER BY key`);
      const map: Record<string, string> = {};
      for (const r of rows ?? []) map[String(r.key)] = String(r.value ?? "");
      return map;
    } catch {
      return { maintenanceMode: "false", allowNewSignups: "true" };
    }
  }

  async patchSettings(body: Record<string, unknown>) {
    for (const [key, value] of Object.entries(body ?? {})) {
      try {
        await prisma.$executeRawUnsafe(
          `INSERT INTO platform_settings (key,value,"updatedAt") VALUES ($1,$2::jsonb,NOW())
           ON CONFLICT (key) DO UPDATE SET value=EXCLUDED.value, "updatedAt"=NOW()`,
          key, JSON.stringify(String(value ?? "")));
      } catch (e) { console.warn("[settings]", key, e); }
    }
    return this.getSettings();
  }
}
