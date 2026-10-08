import { prisma } from "../../config/prisma.js";

function mapRow(r: any) {
  return {
    id: String(r.id), code: String(r.code ?? ""), name: String(r.name ?? ""),
    description: r.description != null ? String(r.description) : null,
    pricePaise: Number(r.pricePaise ?? 0), currency: String(r.currency ?? "INR"),
    billingInterval: r.billingInterval != null ? String(r.billingInterval) : null,
    validityMonths: r.validityMonths != null ? Number(r.validityMonths) : null,
    includedScans: Number(r.includedScans ?? 0),
    retentionDays: r.retentionDays != null ? Number(r.retentionDays) : null,
    storageQuotaBytes: r.storageQuotaBytes != null ? Number(r.storageQuotaBytes) : null,
    maxWarehouses: Number(r.maxWarehouses ?? 1), maxOperators: Number(r.maxOperators ?? 1),
    gstPercent: Number(r.gstPercent ?? 18),
    isCommercial: Boolean(r.isCommercial ?? true), isActive: Boolean(r.isActive ?? true),
    createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
  };
}

export class PlatformPlansService {
  async list(opts: { activeOnly?: boolean; limit?: number }) {
    const limit = Math.min(Math.max(opts.limit ?? 100, 1), 200);
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM plan_configurations ${opts.activeOnly ? 'WHERE "isActive" = true' : ""}
       ORDER BY "pricePaise" ASC NULLS LAST, code ASC LIMIT $1`, limit);
    const items = (rows ?? []).map(mapRow);
    return { total: items.length, items };
  }

  async create(input: any) {
    const code = String(input.code ?? "").trim().toLowerCase();
    const name = String(input.name ?? "").trim();
    if (!code || !name) throw new Error("code and name are required");
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO plan_configurations (
        id, code, name, description, "pricePaise", currency, "billingInterval", "validityMonths",
        "includedScans", "retentionDays", "maxWarehouses", "maxOperators", "gstPercent",
        "isCommercial", "isActive", "createdAt", "updatedAt"
      ) VALUES (gen_random_uuid()::text,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,NOW(),NOW()) RETURNING *`,
      code, name, input.description ?? null, input.pricePaise ?? 0, input.currency ?? "INR",
      input.billingInterval ?? "MONTHLY", input.validityMonths ?? 1, input.includedScans ?? 0,
      input.retentionDays ?? 30, input.maxWarehouses ?? 1, input.maxOperators ?? 1,
      input.gstPercent ?? 18, input.isCommercial ?? true, input.isActive ?? true);
    return mapRow(rows[0]);
  }

  async update(id: string, input: any) {
    const existing = await prisma.$queryRawUnsafe<any[]>(`SELECT * FROM plan_configurations WHERE id = $1 LIMIT 1`, id);
    if (!existing?.length) throw new Error("PLAN_NOT_FOUND");
    const e = existing[0];
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE plan_configurations SET
        name=$2, description=$3, "pricePaise"=$4, currency=$5, "billingInterval"=$6,
        "validityMonths"=$7, "includedScans"=$8, "retentionDays"=$9, "maxWarehouses"=$10,
        "maxOperators"=$11, "gstPercent"=$12, "isCommercial"=$13, "isActive"=$14, "updatedAt"=NOW()
       WHERE id=$1 RETURNING *`,
      id,
      input.name !== undefined ? String(input.name).trim() : e.name,
      input.description !== undefined ? input.description : e.description,
      input.pricePaise !== undefined ? input.pricePaise : e.pricePaise,
      input.currency ?? e.currency, input.billingInterval ?? e.billingInterval,
      input.validityMonths !== undefined ? input.validityMonths : e.validityMonths,
      input.includedScans !== undefined ? input.includedScans : e.includedScans,
      input.retentionDays !== undefined ? input.retentionDays : e.retentionDays,
      input.maxWarehouses !== undefined ? input.maxWarehouses : e.maxWarehouses,
      input.maxOperators !== undefined ? input.maxOperators : e.maxOperators,
      input.gstPercent !== undefined ? input.gstPercent : e.gstPercent,
      input.isCommercial !== undefined ? input.isCommercial : e.isCommercial,
      input.isActive !== undefined ? input.isActive : e.isActive);
    return mapRow(rows[0]);
  }

  async delete(id: string) {
    try {
      const rows = await prisma.$queryRawUnsafe<any[]>(
        `DELETE FROM plan_configurations WHERE id = $1 RETURNING id`,
        id,
      );

      if (!rows?.length) {
        throw new Error("PLAN_NOT_FOUND");
      }

      return {
        id: String(rows[0].id),
        deleted: true,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);

      if (message === "PLAN_NOT_FOUND") {
        throw error;
      }

      if (
        message.includes("foreign key") ||
        message.includes("violates") ||
        message.includes("referenced")
      ) {
        throw new Error("PLAN_IN_USE");
      }

      throw error;
    }
  }

  async setActive(id: string, isActive: boolean) {
    return this.update(id, { isActive });
  }
}
