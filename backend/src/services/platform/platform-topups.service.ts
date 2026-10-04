import { prisma } from "../../config/prisma.js";

function mapPack(r: any) {
  return {
    id: String(r.id), code: String(r.code ?? ""), name: String(r.name ?? ""),
    description: r.description != null ? String(r.description) : null,
    credits: Number(r.credits ?? r.scanCredits ?? 0), pricePaise: Number(r.pricePaise ?? 0),
    currency: String(r.currency ?? "INR"), isActive: Boolean(r.isActive ?? true),
    createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
  };
}

export class PlatformTopupsService {
  async list() {
    for (const sql of [
      `SELECT id, code, name, description, "scanCredits" AS credits, "pricePaise", currency, "isActive", "createdAt" FROM extra_scan_packs ORDER BY "pricePaise" ASC NULLS LAST LIMIT 100`,
      `SELECT id, code, name, description, credits, "pricePaise", currency, "isActive", "createdAt" FROM scan_topup_packs ORDER BY "pricePaise" ASC NULLS LAST LIMIT 100`,
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
    const credits = Number(body.credits ?? 0);
    const pricePaise = Number(body.pricePaise ?? 0);
    if (!code || !name) throw new Error("code and name required");
    try {
      const rows = await prisma.$queryRawUnsafe<any[]>(
        `INSERT INTO extra_scan_packs (id,code,name,description,"scanCredits","pricePaise",currency,"isActive","createdAt","updatedAt")
         VALUES (gen_random_uuid()::text,$1,$2,$3,$4,$5,$6,true,NOW(),NOW()) RETURNING *`,
        code, name, body.description ?? null, credits, pricePaise, body.currency ?? "INR");
      return mapPack({ ...rows[0], credits: rows[0].scanCredits });
    } catch {
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
        await prisma.$executeRawUnsafe(`UPDATE ${t} SET "isActive"=$2 WHERE id=$1`, id, isActive);
        return { id, isActive };
      } catch {}
    }
    return { id, isActive };
  }
}
