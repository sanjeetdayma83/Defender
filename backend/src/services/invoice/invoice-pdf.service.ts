import { createHash } from "node:crypto";
import puppeteer from "puppeteer";
import { readFile } from "node:fs/promises";
import path from "node:path";
import {
  HeadObjectCommand,
  PutObjectCommand,
  GetObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

import { prisma } from "../../config/prisma.js";
import { b2Config } from "../../config/b2.config.js";

const s3 = new S3Client({
  region: b2Config.region,
  endpoint: b2Config.endpoint,
  credentials: {
    accessKeyId: b2Config.keyId,
    secretAccessKey: b2Config.applicationKey,
  },
});

type InvoiceData = {
  id: string;
  companyId: string;
  invoiceNumber: string;
  status: string;
  currency: string;
  customerLegalName: string;
  customerDisplayName: string | null;
  customerGstin: string | null;
  customerPan: string | null;
  customerAddressLine1: string | null;
  customerAddressLine2: string | null;
  customerCity: string | null;
  customerState: string | null;
  customerPostalCode: string | null;
  customerCountry: string;
  customerBillingEmail: string | null;
  customerBillingPhone: string | null;
  subtotalPaise: bigint;
  gstPaise: bigint;
  totalPaise: bigint;
  issuedAt: Date | null;
  paidAt: Date | null;
  pdfStorageKey: string | null;
  pdfChecksum: string | null;
  pdfSizeBytes: bigint | null;
};

type InvoiceItem = {
  id: string;
  itemType: string;
  description: string;
  quantity: number;
  unitPricePaise: bigint;
  taxableAmountPaise: bigint;
  gstPercent: number;
  gstPaise: bigint;
  totalPaise: bigint;
};

type GeneratedPdf = {
  storageKey: string;
  checksum: string;
  sizeBytes: number;
  signedUrl: string;
  expiresIn: number;
};

function money(paise: bigint, currency: string): string {
  return `${currency} ${(Number(paise) / 100).toFixed(2)}`;
}

function safeText(value: string | null | undefined): string {
  return String(value ?? "").trim();
}

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function dateText(value: Date | null | undefined): string {
  if (!value) {
    return "—";
  }

  return value.toISOString().slice(0, 10);
}

function twoDigitWords(value: number): string {
  const ones = [
    "Zero",
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
  ];

  const teens = [
    "Ten",
    "Eleven",
    "Twelve",
    "Thirteen",
    "Fourteen",
    "Fifteen",
    "Sixteen",
    "Seventeen",
    "Eighteen",
    "Nineteen",
  ];

  const tens = [
    "",
    "",
    "Twenty",
    "Thirty",
    "Forty",
    "Fifty",
    "Sixty",
    "Seventy",
    "Eighty",
    "Ninety",
  ];

  if (value < 10) {
    return ones[value];
  }

  if (value < 20) {
    return teens[value - 10];
  }

  return `${tens[Math.floor(value / 10)]}${
    value % 10 ? ` ${ones[value % 10]}` : ""
  }`;
}

function indianNumberWords(value: number): string {
  if (value === 0) {
    return "Zero";
  }

  let remaining = Math.floor(value);
  const parts: string[] = [];

  const crore = Math.floor(remaining / 10_000_000);
  remaining %= 10_000_000;

  const lakh = Math.floor(remaining / 100_000);
  remaining %= 100_000;

  const thousand = Math.floor(remaining / 1_000);
  remaining %= 1_000;

  const hundred = Math.floor(remaining / 100);
  remaining %= 100;

  if (crore) {
    parts.push(`${indianNumberWords(crore)} Crore`);
  }

  if (lakh) {
    parts.push(`${twoDigitWords(lakh)} Lakh`);
  }

  if (thousand) {
    parts.push(`${twoDigitWords(thousand)} Thousand`);
  }

  if (hundred) {
    parts.push(`${twoDigitWords(hundred)} Hundred`);
  }

  if (remaining) {
    parts.push(twoDigitWords(remaining));
  }

  return parts.join(" ");
}

function amountInWords(paise: bigint): string {
  const numeric = Number(paise ?? 0n);
  const rupees = Math.floor(numeric / 100);
  const remainderPaise = numeric % 100;

  const rupeeWords = indianNumberWords(rupees);

  if (remainderPaise === 0) {
    return `Indian Rupees ${rupeeWords} Only`;
  }

  return `Indian Rupees ${rupeeWords} and ${remainderPaise}/100 Only`;
}

async function loadInvoiceTemplate(): Promise<string> {
  const currentModuleDirectory = path.dirname(
    new URL(import.meta.url).pathname,
  );

  const candidates = [
    path.resolve(
      process.cwd(),
      "src",
      "templates",
      "invoice",
      "invoice-template.html",
    ),

    path.resolve(
      process.cwd(),
      "templates",
      "invoice",
      "invoice-template.html",
    ),

    path.resolve(
      currentModuleDirectory,
      "../../templates/invoice/invoice-template.html",
    ),

    path.resolve(
      currentModuleDirectory,
      "../../../src/templates/invoice/invoice-template.html",
    ),
  ];

  let lastError: unknown = null;

  for (const filePath of candidates) {
    try {
      return await readFile(filePath, "utf8");
    } catch (error) {
      lastError = error;
    }
  }

  throw new Error(
    `INVOICE_TEMPLATE_NOT_FOUND: ${
      lastError instanceof Error
        ? lastError.message
        : "invoice-template.html could not be loaded."
    }`,
  );
}

async function generatePdfBuffer(
  invoice: InvoiceData,
  items: InvoiceItem[],
): Promise<Buffer> {
  const template = await loadInvoiceTemplate();

  const item = items[0];

  if (!item) {
    throw new Error("INVOICE_LINE_ITEM_NOT_FOUND");
  }

  const itemWithMetadata = item as InvoiceItem & {
    metadata?: unknown;
  };

  const metadata =
    itemWithMetadata.metadata &&
    typeof itemWithMetadata.metadata === "object" &&
    !Array.isArray(itemWithMetadata.metadata)
      ? (itemWithMetadata.metadata as Record<string, unknown>)
      : {};

  const description = String(
    item.description ?? "Loss Defender Pro SaaS",
  );

  const planMatch = description.match(
    /^(.+?)\s+plan\s*-\s*(MONTHLY|YEARLY)$/i,
  );

  const planName = planMatch
    ? `${planMatch[1].trim()} Plan`
    : description;

  const billingInterval =
    planMatch?.[2]?.toUpperCase() ?? "MONTHLY";

  const taxablePaise =
    item.taxableAmountPaise ??
    invoice.subtotalPaise ??
    0n;

  const gstPaise =
    invoice.gstPaise ??
    item.gstPaise ??
    0n;

  // PrimeCore Enterprises is registered in Haryana.
  const customerState = String(
    invoice.customerState ?? "",
  )
    .trim()
    .toLowerCase();

  const intraState =
    customerState === "haryana" ||
    customerState === "hr";

  const cgstPaise = intraState
    ? gstPaise / 2n
    : 0n;

  const sgstPaise = intraState
    ? gstPaise - cgstPaise
    : 0n;

  const igstPaise = intraState
    ? 0n
    : gstPaise;

  const gstRate = Number(
    item.gstPercent ?? 18,
  );

  const customerAddress = [
    invoice.customerAddressLine1,
    invoice.customerAddressLine2,
    [invoice.customerCity, invoice.customerState]
      .filter(Boolean)
      .join(", "),
    invoice.customerPostalCode,
    invoice.customerCountry,
  ]
    .filter(Boolean)
    .map(escapeHtml)
    .join("<br>");

  const stateCode =
    customerState === "haryana" ||
    customerState === "hr"
      ? "06"
      : "";

  const placeOfSupply = [
    invoice.customerState,
    stateCode
      ? `State Code: ${stateCode}`
      : "",
  ]
    .filter(Boolean)
    .map(escapeHtml)
    .join(" | ");

  const providerPaymentId = String(
    metadata.providerPaymentId ?? "—",
  );

  const providerOrderId = String(
    metadata.providerOrderId ?? "—",
  );

  const subscriptionId = String(
    metadata.subscriptionId ?? "—",
  );

  const validityMonthsRaw = Number(
    metadata.validityMonths ?? (
      billingInterval === "YEARLY"
        ? 12
        : 1
    ),
  );

  const includedScans = String(
    metadata.includedScans ??
      "As per selected plan",
  );

  const retentionDays = String(
    metadata.retentionDays ??
      "As per selected plan",
  );

  const data: Record<string, string> = {
    invoiceNumber: escapeHtml(
      invoice.invoiceNumber,
    ),

    invoiceDate: escapeHtml(
      dateText(invoice.issuedAt),
    ),

    paymentDate: escapeHtml(
      dateText(invoice.paidAt ?? invoice.issuedAt),
    ),

    paymentStatus: escapeHtml(
      String(invoice.status ?? "PAID"),
    ),

    paymentMethod: "Razorpay",

    customerName: escapeHtml(
      invoice.customerLegalName ||
        invoice.customerDisplayName ||
        "Customer",
    ),

    customerAddress,

    customerGstin: escapeHtml(
      invoice.customerGstin || "—",
    ),

    contactPerson: escapeHtml(
      invoice.customerDisplayName ||
        invoice.customerLegalName ||
        "—",
    ),

    billingEmail: escapeHtml(
      invoice.customerBillingEmail ||
        "—",
    ),

    billingPhone: escapeHtml(
      invoice.customerBillingPhone ||
        "—",
    ),

    placeOfSupply:
      placeOfSupply || "—",

    serviceName: escapeHtml(
      planName,
    ),

    serviceDescription:
      "Loss Defender Pro Warehouse Intelligence Platform subscription",

    validity:
      `${validityMonthsRaw} ${
        validityMonthsRaw === 1
          ? "Month"
          : "Months"
      }`,

    includedScans: escapeHtml(
      includedScans,
    ),

    retentionDays: escapeHtml(
      retentionDays,
    ),

    // SAC is not stored in the current invoice item record.
    sac: escapeHtml(
      String(metadata.sac ?? "—"),
    ),

    rate: money(
      item.unitPricePaise,
      invoice.currency,
    ),

    gstRate: `${gstRate}%`,

    taxableAmount: money(
      taxablePaise,
      invoice.currency,
    ),

    amountInWords: escapeHtml(
      amountInWords(
        invoice.totalPaise,
      ),
    ),

    discountAmount: money(
      0n,
      invoice.currency,
    ),

    cgstRate: intraState
      ? `${gstRate / 2}%`
      : "0%",

    cgstAmount: money(
      cgstPaise,
      invoice.currency,
    ),

    sgstRate: intraState
      ? `${gstRate / 2}%`
      : "0%",

    sgstAmount: money(
      sgstPaise,
      invoice.currency,
    ),

    igstRate: intraState
      ? "0%"
      : `${gstRate}%`,

    igstAmount: money(
      igstPaise,
      invoice.currency,
    ),

    totalTax: money(
      gstPaise,
      invoice.currency,
    ),

    grandTotal: money(
      invoice.totalPaise,
      invoice.currency,
    ),

    razorpayPaymentId:
      escapeHtml(providerPaymentId),

    razorpayOrderId:
      escapeHtml(providerOrderId),

    subscriptionId:
      escapeHtml(subscriptionId),

    balanceDue:
      String(invoice.status)
        .toUpperCase() === "PAID"
        ? money(0n, invoice.currency)
        : money(
            invoice.totalPaise,
            invoice.currency,
          ),
  };

  let html = template;

  for (const [key, value] of Object.entries(data)) {
    html = html
      .split(`{{${key}}}`)
      .join(value);
  }

  if (intraState) {
    html = html
      .replace(
        '<div class="total-row" id="cgstRow">',
        '<div class="total-row" id="cgstRow" style="display:flex">',
      )
      .replace(
        '<div class="total-row" id="sgstRow">',
        '<div class="total-row" id="sgstRow" style="display:flex">',
      )
      .replace(
        '<div class="total-row" id="igstRow" style="display:none">',
        '<div class="total-row" id="igstRow" style="display:none">',
      );
  } else {
    html = html
      .replace(
        '<div class="total-row" id="cgstRow">',
        '<div class="total-row" id="cgstRow" style="display:none">',
      )
      .replace(
        '<div class="total-row" id="sgstRow">',
        '<div class="total-row" id="sgstRow" style="display:none">',
      )
      .replace(
        '<div class="total-row" id="igstRow" style="display:none">',
        '<div class="total-row" id="igstRow" style="display:flex">',
      );
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
    ],
  });

  try {
    const page = await browser.newPage();

    await page.setViewport({
      width: 1240,
      height: 1754,
      deviceScaleFactor: 1,
    });

    await page.setContent(html, {
      waitUntil: "domcontentloaded",
    });

    await page.emulateMediaType("print");

    await page.evaluate(async () => {
      if (document.fonts?.ready) {
        await document.fonts.ready;
      }
    });

    const pdf = await page.pdf({
      format: "A4",
      printBackground: true,
      preferCSSPageSize: true,
      margin: {
        top: "0",
        right: "0",
        bottom: "0",
        left: "0",
      },
    });

    return Buffer.from(pdf);
  } finally {
    await browser.close();
  }
}
export class InvoicePdfService {
  private async getInvoice(
    companyId: string,
    invoiceId: string,
  ): Promise<{ invoice: InvoiceData; items: InvoiceItem[] }> {
    const invoiceRows = await prisma.$queryRawUnsafe<InvoiceData[]>(
      `
        SELECT
          "id",
          "companyId",
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
          "pdfStorageKey",
          "pdfChecksum",
          "pdfSizeBytes"
        FROM "invoices"
        WHERE "id" = $1
          AND "companyId" = $2
        LIMIT 1
      `,
      invoiceId,
      companyId,
    );

    if (invoiceRows.length !== 1) {
      throw new Error("INVOICE_NOT_FOUND");
    }

    const itemRows = await prisma.$queryRawUnsafe<InvoiceItem[]>(
      `
        SELECT
          "id",
          "itemType",
          "description",
          "quantity",
          "unitPricePaise",
          "taxableAmountPaise",
          "gstPercent",
          "gstPaise",
          "totalPaise"
        FROM "invoice_items"
        WHERE "invoiceId" = $1
        ORDER BY "createdAt" ASC
      `,
      invoiceId,
    );

    return {
      invoice: invoiceRows[0],
      items: itemRows,
    };
  }

  private async createSignedUrl(storageKey: string): Promise<{
    signedUrl: string;
    expiresIn: number;
  }> {
    const expiresIn = Math.max(
      1,
      Math.min(
        Number.isFinite(b2Config.signedUrlTtl)
          ? b2Config.signedUrlTtl
          : 900,
        86400,
      ),
    );

    const signedUrl = await getSignedUrl(
      s3,
      new GetObjectCommand({
        Bucket: b2Config.bucketName,
        Key: storageKey,
      }),
      { expiresIn },
    );

    return { signedUrl, expiresIn };
  }

  async generateOrGet(
    companyId: string,
    invoiceId: string,
  ): Promise<GeneratedPdf> {
    const { invoice, items } = await this.getInvoice(companyId, invoiceId);

    if (invoice.pdfStorageKey && invoice.pdfStorageKey.endsWith("-custom-v2.pdf")) {
      try {
        await s3.send(
          new HeadObjectCommand({
            Bucket: b2Config.bucketName,
            Key: invoice.pdfStorageKey,
          }),
        );

        const signed = await this.createSignedUrl(invoice.pdfStorageKey);

        return {
          storageKey: invoice.pdfStorageKey,
          checksum: invoice.pdfChecksum ?? "",
          sizeBytes: Number(invoice.pdfSizeBytes ?? 0n),
          signedUrl: signed.signedUrl,
          expiresIn: signed.expiresIn,
        };
      } catch {
        // Metadata exists but the object is unavailable.
        // Regenerate the PDF and repair the storage metadata.
      }
    }

    const pdfBuffer = await generatePdfBuffer(invoice, items);
    const checksum = createHash("sha256")
      .update(pdfBuffer)
      .digest("hex");

    const year = invoice.issuedAt
      ? invoice.issuedAt.getUTCFullYear()
      : new Date().getUTCFullYear();

    const storageKey = [
      "companies",
      companyId,
      "invoices",
      String(year),
      `${invoice.invoiceNumber}-custom-v2.pdf`,
    ].join("/");

    await s3.send(
      new PutObjectCommand({
        Bucket: b2Config.bucketName,
        Key: storageKey,
        Body: pdfBuffer,
        ContentType: "application/pdf",
        Metadata: {
          companyId,
          invoiceId: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          checksum,
        },
      }),
    );

    await prisma.$executeRawUnsafe(
      `
        UPDATE "invoices"
        SET
          "pdfStorageKey" = $1,
          "pdfChecksum" = $2,
          "pdfSizeBytes" = $3,
          "updatedAt" = CURRENT_TIMESTAMP
        WHERE "id" = $4
          AND "companyId" = $5
      `,
      storageKey,
      checksum,
      BigInt(pdfBuffer.length),
      invoice.id,
      companyId,
    );

    const signed = await this.createSignedUrl(storageKey);

    return {
      storageKey,
      checksum,
      sizeBytes: pdfBuffer.length,
      signedUrl: signed.signedUrl,
      expiresIn: signed.expiresIn,
    };
  }
}

export const invoicePdfService = new InvoicePdfService();
