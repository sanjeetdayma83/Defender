import { randomUUID } from "node:crypto";
import { prisma } from "../../config/prisma.js";

type BillingPaymentRow = {
  id: string;
  companyId: string;
  provider: string;
  providerOrderId: string;
  providerPaymentId: string | null;
  status: string;
  plan: string;
  billingInterval: string;
  currency: string;
  amountPaise: bigint;
  gstPaise: bigint;
  totalPaise: bigint;
  paidAt: Date | null;
};

type CompanyRow = {
  id: string;
  companyName: string;
  email: string | null;
  phone: string | null;
  gst: string | null;
  pan: string | null;
  address: unknown;
  timezone: string | null;
  currency: string | null;
};

type InvoiceTransactionClient = {
  $queryRawUnsafe<T = unknown>(
    query: TemplateStringsArray | string,
    ...values: unknown[]
  ): Promise<T>;
  $executeRawUnsafe(
    query: TemplateStringsArray | string,
    ...values: unknown[]
  ): Promise<number>;
};
type InvoiceRow = {
  id: string;
  companyId: string;
  billingPaymentId: string | null;
  invoiceNumber: string;
  status: string;
  currency: string;
  customerLegalName: string;
  customerDisplayName: string | null;
  customerGstin: string | null;
  customerPan: string | null;
  billingEmail: string | null;
  billingPhone: string | null;
  subtotalPaise: bigint;
  gstPaise: bigint;
  totalPaise: bigint;
  issuedAt: Date | null;
  paidAt: Date | null;
};

function normalizeAddress(address: unknown): Record<string, string> {
  if (!address || typeof address !== "object" || Array.isArray(address)) {
    return {};
  }

  const source = address as Record<string, unknown>;
  const result: Record<string, string> = {};

  for (const key of ["line1", "line2", "city", "state", "postalCode", "pincode", "country"]) {
    const value = source[key];
    if (typeof value === "string" && value.trim()) {
      result[key] = value.trim();
    }
  }

  return result;
}

function formatInvoiceNumber(year: number, sequence: number): string {
  return `INV-${year}-${String(sequence).padStart(6, "0")}`;
}

export class InvoiceService {
  async createFromBillingPayment(
    companyId: string,
    billingPaymentId: string,
  ): Promise<InvoiceRow> {
    if (!companyId || !billingPaymentId) {
      throw new Error("companyId and billingPaymentId are required");
    }

    return prisma.$transaction((tx) =>
      this.createFromBillingPaymentInTransaction(
        tx,
        companyId,
        billingPaymentId,
      ),
    );
  }

  async createFromBillingPaymentInTransaction(
    tx: InvoiceTransactionClient,
    companyId: string,
    billingPaymentId: string,
  ): Promise<InvoiceRow> {
    if (!companyId || !billingPaymentId) {
      throw new Error("companyId and billingPaymentId are required");
    }

    const existingRows = await tx.$queryRawUnsafe<InvoiceRow[]>(
      `
      SELECT
        i.*,
        COALESCE(
          jsonb_agg(
            jsonb_build_object(
              'id', ii."id",
              'itemType', ii."itemType",
              'description', ii."description",
              'quantity', ii."quantity",
              'unitPricePaise', ii."unitPricePaise",
              'taxableAmountPaise', ii."taxableAmountPaise",
              'gstPercent', ii."gstPercent",
              'gstPaise', ii."gstPaise",
              'totalPaise', ii."totalPaise",
              'referenceType', ii."referenceType",
              'referenceId', ii."referenceId",
              'metadata', ii."metadata"
            )
            ORDER BY ii."createdAt"
          ) FILTER (WHERE ii."id" IS NOT NULL),
          '[]'::jsonb
        ) AS "items"
      FROM "invoices" i
      LEFT JOIN "invoice_items" ii
        ON ii."invoiceId" = i."id"
      WHERE i."companyId" = $1
        AND i."billingPaymentId" = $2
      GROUP BY i."id"
      LIMIT 1
      `,
      companyId,
      billingPaymentId,
    );

    if (existingRows.length === 1) {
      return existingRows[0];
    }

    const paymentRows = await tx.$queryRawUnsafe<any[]>(
      `
      SELECT *
      FROM "BillingPayment"
      WHERE "id" = $1
        AND "companyId" = $2
      FOR UPDATE
      `,
      billingPaymentId,
      companyId,
    );

    if (paymentRows.length !== 1) {
      throw new Error("BILLING_PAYMENT_NOT_FOUND");
    }

    const payment = paymentRows[0];

    if (payment.status !== "SUCCESS") {
      throw new Error("INVOICE_REQUIRES_SUCCESSFUL_PAYMENT");
    }

    const companyRows = await tx.$queryRawUnsafe<any[]>(
      `
      SELECT
        "id",
        "companyName",
        "email",
        "phone",
        "gst",
        "pan",
        "address",
        "currency"
      FROM "Company"
      WHERE "id" = $1
      LIMIT 1
      `,
      companyId,
    );

    if (companyRows.length !== 1) {
      throw new Error("COMPANY_NOT_FOUND");
    }

    const company = companyRows[0];
    const now = new Date();
    const year = now.getUTCFullYear();

    const sequenceRows = await tx.$queryRawUnsafe<any[]>(
      `
      INSERT INTO "invoice_sequences" (
        "id",
        "year",
        "nextValue",
        "createdAt",
        "updatedAt"
      )
      VALUES (
        gen_random_uuid()::text,
        $1,
        2,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
      ON CONFLICT ("year")
      DO UPDATE SET
        "nextValue" = "invoice_sequences"."nextValue" + 1,
        "updatedAt" = CURRENT_TIMESTAMP
      RETURNING
        ("nextValue" - 1) AS "sequenceValue"
      `,
      year,
    );

    if (sequenceRows.length !== 1) {
      throw new Error("INVOICE_SEQUENCE_ALLOCATION_FAILED");
    }

    const sequenceValue = Number(sequenceRows[0].sequenceValue);
    const invoiceNumber = `INV-${year}-${String(sequenceValue).padStart(6, "0")}`;

    const subtotalPaise = BigInt(payment.amountPaise);
    const gstPaise = BigInt(payment.gstPaise ?? 0);
    const totalPaise = BigInt(payment.totalPaise);

    const companyAddress =
      company.address && typeof company.address === "object"
        ? company.address
        : {};

    const customerLegalName =
      company.companyName || "Loss Defender Pro Customer";

    const invoiceRows = await tx.$queryRawUnsafe<InvoiceRow[]>(
      `
      INSERT INTO "invoices" (
        "id",
        "companyId",
        "billingPaymentId",
        "invoiceNumber",
        "status",
        "currency",
        "customerLegalName",
        "customerDisplayName",
        "customerGstin",
        "customerPan",
        "customerAddressLine1",
        "customerAddressLine2",
        "customerCity",
        "customerState",
        "customerPostalCode",
        "customerCountry",
        "customerBillingEmail",
        "customerBillingPhone",
        "subtotalPaise",
        "gstPaise",
        "totalPaise",
        "issuedAt",
        "paidAt",
        "createdAt",
        "updatedAt"
      )
      VALUES (
        gen_random_uuid()::text,
        $1,
        $2,
        $3,
        'PAID',
        COALESCE($4, 'INR'),
        $5,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        COALESCE($13, 'IN'),
        $14,
        $15,
        $16,
        $17,
        $18,
        $19,
        $19,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
      RETURNING *
      `,
      companyId,
      billingPaymentId,
      invoiceNumber,
      payment.currency ?? company.currency ?? "INR",
      customerLegalName,
      company.gst ?? null,
      company.pan ?? null,
      companyAddress.line1 ?? companyAddress.addressLine1 ?? null,
      companyAddress.line2 ?? companyAddress.addressLine2 ?? null,
      companyAddress.city ?? null,
      companyAddress.state ?? null,
      companyAddress.postalCode ?? companyAddress.pincode ?? null,
      companyAddress.country ?? "IN",
      company.email ?? null,
      company.phone ?? null,
      subtotalPaise,
      gstPaise,
      totalPaise,
      now,
    );

    if (invoiceRows.length !== 1) {
      throw new Error("INVOICE_CREATION_FAILED");
    }

    const invoice = invoiceRows[0];

    await tx.$executeRawUnsafe(
      `
      INSERT INTO "invoice_items" (
        "id",
        "invoiceId",
        "itemType",
        "description",
        "quantity",
        "unitPricePaise",
        "taxableAmountPaise",
        "gstPercent",
        "gstPaise",
        "totalPaise",
        "referenceType",
        "referenceId",
        "metadata",
        "createdAt"
      )
      VALUES (
        gen_random_uuid()::text,
        $1,
        'PLAN',
        $2,
        1,
        $3,
        $4,
        $5,
        $6,
        $7,
        'BillingPayment',
        $8,
        $9::jsonb,
        CURRENT_TIMESTAMP
      )
      `,
      invoice.id,
      `${String(payment.plan).toUpperCase()} plan - ${payment.billingInterval}`,
      subtotalPaise,
      subtotalPaise,
      gstPaise > 0n && subtotalPaise > 0n
        ? Number((gstPaise * 100n) / subtotalPaise)
        : 0,
      gstPaise,
      totalPaise,
      billingPaymentId,
      JSON.stringify({
        provider: payment.provider,
        providerOrderId: payment.providerOrderId,
        providerPaymentId: payment.providerPaymentId,
      }),
    );

    return invoice;
  }

  async listForCompany(
    companyId: string,
    limit = 100,
  ): Promise<InvoiceRow[]> {
    const safeLimit = Math.min(
      Math.max(Math.trunc(limit), 1),
      500,
    );

    return prisma.$queryRawUnsafe<InvoiceRow[]>(
      `
      SELECT
        "id",
        "companyId",
        "billingPaymentId",
        "invoiceNumber",
        "status",
        "currency",
        "customerLegalName",
        "customerDisplayName",
        "customerGstin",
        "customerPan",
        "customerBillingEmail",
        "customerBillingPhone",
        "subtotalPaise",
        "gstPaise",
        "totalPaise",
        "issuedAt",
        "paidAt"
      FROM "invoices"
      WHERE "companyId" = $1
      ORDER BY COALESCE("issuedAt", "createdAt") DESC
      LIMIT $2
      `,
      companyId,
      safeLimit,
    );
  }
  async getById(companyId: string, invoiceId: string): Promise<InvoiceRow | null> {
    const rows = await prisma.$queryRawUnsafe<InvoiceRow[]>(`
      SELECT
        "id",
        "companyId",
        "billingPaymentId",
        "invoiceNumber",
        "status",
        "currency",
        "customerLegalName",
        "customerDisplayName",
        "customerGstin",
        "customerPan",
        "customerBillingEmail",
        "customerBillingPhone",
        "subtotalPaise",
        "gstPaise",
        "totalPaise",
        "issuedAt",
        "paidAt"
      FROM "invoices"
      WHERE "id" = $1
        AND "companyId" = $2
      LIMIT 1
    `, invoiceId, companyId);

    return rows[0] ?? null;
  }

  async getByBillingPayment(
    companyId: string,
    billingPaymentId: string,
  ): Promise<InvoiceRow | null> {
    const rows = await prisma.$queryRawUnsafe<InvoiceRow[]>(`
      SELECT
        "id",
        "companyId",
        "billingPaymentId",
        "invoiceNumber",
        "status",
        "currency",
        "customerLegalName",
        "customerDisplayName",
        "customerGstin",
        "customerPan",
        "customerBillingEmail",
        "customerBillingPhone",
        "subtotalPaise",
        "gstPaise",
        "totalPaise",
        "issuedAt",
        "paidAt"
      FROM "invoices"
      WHERE "billingPaymentId" = $1
        AND "companyId" = $2
      LIMIT 1
    `, billingPaymentId, companyId);

    return rows[0] ?? null;
  }
}

export const invoiceService = new InvoiceService();
