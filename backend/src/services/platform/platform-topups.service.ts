import { prisma } from "../../config/prisma.js";

type ColumnMeta = {
  column_name: string;
  data_type: string;
  column_default: string | null;
  is_nullable: string;
};

type ResolvedTopupSchema = {
  table: string;
  id: string;
  idType: string;
  code: string;
  name: string;
  description?: string;
  credits: string;
  pricePaise: string;
  currency?: string;
  isActive?: string;
  gstPercent?: string;
  sortOrder?: string;
  createdAt?: string;
  updatedAt?: string;
};

function quoteIdentifier(value: string): string {
  return `"${value.replace(/"/g, '""')}"`;
}

function pick(
  columns: Map<string, ColumnMeta>,
  names: string[],
): string | undefined {
  for (const name of names) {
    const item = columns.get(name.toLowerCase());
    if (item) return item.column_name;
  }
  return undefined;
}

function toNumber(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "bigint") return Number(value);
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function mapPack(row: any) {
  return {
    id: String(row.id),
    code: String(row.code ?? ""),
    name: String(row.name ?? ""),
    description:
      row.description != null ? String(row.description) : null,
    credits: toNumber(row.credits),
    pricePaise: toNumber(row.pricePaise),
    currency: String(row.currency ?? "INR"),
    isActive: row.isActive !== false,
    gstPercent: toNumber(row.gstPercent ?? 18),
    sortOrder: toNumber(row.sortOrder ?? 0),
    createdAt: row.createdAt
      ? new Date(row.createdAt).toISOString()
      : new Date().toISOString(),
  };
}

export class PlatformTopupsService {
  private async resolveSchema(): Promise<ResolvedTopupSchema> {
    const candidates = [
      "extra_scan_packs",
      "scan_topup_packs",
      "scan_topups",
      "topup_packs",
      "top_up_packs",
    ];

    const placeholders = candidates
      .map((_, index) => `$${index + 1}`)
      .join(", ");

    const tables = await prisma.$queryRawUnsafe<
      { table_name: string }[]
    >(
      `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name IN (${placeholders})
      ORDER BY CASE table_name
        WHEN 'extra_scan_packs' THEN 1
        WHEN 'scan_topup_packs' THEN 2
        WHEN 'scan_topups' THEN 3
        WHEN 'topup_packs' THEN 4
        WHEN 'top_up_packs' THEN 5
        ELSE 99
      END
      `,
      ...candidates,
    );

    const table = tables[0]?.table_name;

    if (!table) {
      throw new Error("TOPUP_TABLE_NOT_FOUND");
    }

    const columns = await prisma.$queryRawUnsafe<ColumnMeta[]>(
      `
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = $1
      ORDER BY ordinal_position
      `,
      table,
    );

    const byName = new Map(
      columns.map((column) => [
        column.column_name.toLowerCase(),
        column,
      ]),
    );

    const idColumn = pick(byName, ["id"]);
    const codeColumn = pick(byName, ["code"]);
    const nameColumn = pick(byName, ["name"]);
    const creditsColumn = pick(byName, [
      "scanCredits",
      "scan_credits",
      "credits",
    ]);
    const priceColumn = pick(byName, [
      "pricePaise",
      "price_paise",
      "price",
      "amountPaise",
      "amount_paise",
      "amount",
    ]);

    if (
      !idColumn ||
      !codeColumn ||
      !nameColumn ||
      !creditsColumn ||
      !priceColumn
    ) {
      throw new Error("TOPUP_TABLE_SCHEMA_UNSUPPORTED");
    }

    const idMeta = byName.get(idColumn.toLowerCase());

    return {
      table,
      id: idColumn,
      idType: idMeta?.data_type ?? "text",
      code: codeColumn,
      name: nameColumn,
      description: pick(byName, ["description"]),
      credits: creditsColumn,
      pricePaise: priceColumn,
      currency: pick(byName, ["currency"]),
      isActive: pick(byName, ["isActive", "is_active"]),
      gstPercent: pick(byName, ["gstPercent", "gst_percent"]),
      sortOrder: pick(byName, ["sortOrder", "sort_order"]),
      createdAt: pick(byName, ["createdAt", "created_at"]),
      updatedAt: pick(byName, ["updatedAt", "updated_at"]),
    };
  }

  private selectSql(schema: ResolvedTopupSchema): string {
    const fields = [
      `${quoteIdentifier(schema.id)} AS id`,
      `${quoteIdentifier(schema.code)} AS code`,
      `${quoteIdentifier(schema.name)} AS name`,
      schema.description
        ? `${quoteIdentifier(schema.description)} AS description`
        : `NULL::text AS description`,
      `${quoteIdentifier(schema.credits)} AS credits`,
      `${quoteIdentifier(schema.pricePaise)} AS "pricePaise"`,
      schema.currency
        ? `${quoteIdentifier(schema.currency)} AS currency`
        : `'INR'::text AS currency`,
      schema.isActive
        ? `${quoteIdentifier(schema.isActive)} AS "isActive"`
        : `TRUE AS "isActive"`,
      schema.gstPercent
        ? `${quoteIdentifier(schema.gstPercent)} AS "gstPercent"`
        : `18 AS "gstPercent"`,
      schema.sortOrder
        ? `${quoteIdentifier(schema.sortOrder)} AS "sortOrder"`
        : `0 AS "sortOrder"`,
      schema.createdAt
        ? `${quoteIdentifier(schema.createdAt)} AS "createdAt"`
        : `NOW() AS "createdAt"`,
    ];

    return fields.join(", ");
  }

  async list() {
    const schema = await this.resolveSchema();

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT ${this.selectSql(schema)}
      FROM ${quoteIdentifier(schema.table)}
      ORDER BY ${quoteIdentifier(schema.pricePaise)} ASC NULLS LAST
      LIMIT 100
      `,
    );

    return {
      total: rows.length,
      items: rows.map(mapPack),
    };
  }

  async create(body: any) {
    const code = String(body.code ?? "").trim().toLowerCase();
    const name = String(body.name ?? "").trim();
    const credits = Number(body.credits ?? 0);
    const pricePaise = Number(body.pricePaise ?? 0);

    if (!code || !name) {
      throw new Error("code and name required");
    }

    if (!Number.isFinite(credits) || credits <= 0) {
      throw new Error("credits must be greater than 0");
    }

    if (!Number.isFinite(pricePaise) || pricePaise < 0) {
      throw new Error("pricePaise must be 0 or greater");
    }

    const schema = await this.resolveSchema();

    const columns: string[] = [];
    const valuesSql: string[] = [];
    const values: unknown[] = [];

    const addValue = (column: string | undefined, value: unknown) => {
      if (!column) return;
      columns.push(quoteIdentifier(column));
      values.push(value);
      valuesSql.push(`$${values.length}`);
    };

    if (schema.idType === "uuid") {
      columns.push(quoteIdentifier(schema.id));
      valuesSql.push("gen_random_uuid()");
    } else if (
      schema.idType === "text" ||
      schema.idType === "character varying" ||
      schema.idType === "character"
    ) {
      columns.push(quoteIdentifier(schema.id));
      valuesSql.push("gen_random_uuid()::text");
    } else {
      throw new Error("TOPUP_ID_SCHEMA_UNSUPPORTED");
    }

    addValue(schema.code, code);
    addValue(schema.name, name);
    addValue(schema.description, body.description ?? null);
    addValue(schema.credits, credits);
    addValue(schema.pricePaise, pricePaise);
    addValue(schema.currency, body.currency ?? "INR");
    addValue(schema.gstPercent, body.gstPercent ?? 18);
    addValue(schema.isActive, true);
    addValue(schema.sortOrder, body.sortOrder ?? 0);

    if (schema.createdAt) {
      columns.push(quoteIdentifier(schema.createdAt));
      valuesSql.push("NOW()");
    }

    if (schema.updatedAt) {
      columns.push(quoteIdentifier(schema.updatedAt));
      valuesSql.push("NOW()");
    }

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      INSERT INTO ${quoteIdentifier(schema.table)}
        (${columns.join(", ")})
      VALUES
        (${valuesSql.join(", ")})
      RETURNING ${this.selectSql(schema)}
      `,
      ...values,
    );

    return mapPack(rows[0]);
  }

  async update(id: string, body: any) {
    const schema = await this.resolveSchema();

    const assignments: string[] = [];
    const values: unknown[] = [];

    const addSet = (column: string | undefined, value: unknown) => {
      if (!column) return;
      values.push(value);
      assignments.push(
        `${quoteIdentifier(column)} = $${values.length}`,
      );
    };

    if (body.code !== undefined) {
      addSet(schema.code, String(body.code).trim().toLowerCase());
    }

    if (body.name !== undefined) {
      addSet(schema.name, String(body.name).trim());
    }

    if (body.description !== undefined) {
      addSet(schema.description, body.description);
    }

    if (body.credits !== undefined) {
      addSet(schema.credits, Number(body.credits));
    }

    if (body.pricePaise !== undefined) {
      addSet(schema.pricePaise, Number(body.pricePaise));
    }

    if (body.currency !== undefined) {
      addSet(schema.currency, String(body.currency));
    }

    if (body.isActive !== undefined) {
      addSet(schema.isActive, Boolean(body.isActive));
    }

    if (body.gstPercent !== undefined) {
      addSet(schema.gstPercent, Number(body.gstPercent));
    }

    if (body.sortOrder !== undefined) {
      addSet(schema.sortOrder, Number(body.sortOrder));
    }

    if (schema.updatedAt) {
      assignments.push(
        `${quoteIdentifier(schema.updatedAt)} = NOW()`,
      );
    }

    if (assignments.length === 0) {
      const rows = await prisma.$queryRawUnsafe<any[]>(
        `
        SELECT ${this.selectSql(schema)}
        FROM ${quoteIdentifier(schema.table)}
        WHERE ${quoteIdentifier(schema.id)} = $1
        LIMIT 1
        `,
        id,
      );

      if (!rows[0]) {
        throw new Error("TOPUP_NOT_FOUND");
      }

      return mapPack(rows[0]);
    }

    values.push(id);

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      UPDATE ${quoteIdentifier(schema.table)}
      SET ${assignments.join(", ")}
      WHERE ${quoteIdentifier(schema.id)} = $${values.length}
      RETURNING ${this.selectSql(schema)}
      `,
      ...values,
    );

    if (!rows[0]) {
      throw new Error("TOPUP_NOT_FOUND");
    }

    return mapPack(rows[0]);
  }

  async setActive(id: string, isActive: boolean) {
    return this.update(id, { isActive });
  }

  async delete(id: string) {
    const schema = await this.resolveSchema();

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      DELETE FROM ${quoteIdentifier(schema.table)}
      WHERE ${quoteIdentifier(schema.id)} = $1
      RETURNING ${quoteIdentifier(schema.id)} AS id
      `,
      id,
    );

    if (!rows[0]) {
      throw new Error("TOPUP_NOT_FOUND");
    }

    return {
      id: String(rows[0].id),
      deleted: true,
    };
  }
}
