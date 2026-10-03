import { createHash } from "node:crypto";
import PDFDocument from "pdfkit";
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

function generatePdfBuffer(
  invoice: InvoiceData,
  items: InvoiceItem[],
): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];

    const doc = new PDFDocument({
      size: "A4",
      margin: 48,
      info: {
        Title: `Invoice ${invoice.invoiceNumber}`,
        Author: "Loss Defender Pro",
        Subject: "Tax Invoice",
      },
    });

    doc.on("data", (chunk: Buffer) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    const pageWidth = 595.28;
    const contentWidth = pageWidth - 96;

    doc
      .fontSize(20)
      .font("Helvetica-Bold")
      .text("LOSS DEFENDER PRO", 48, 48);

    doc
      .fontSize(9)
      .font("Helvetica")
      .text("Warehouse Intelligence Platform", 48, 73);

    doc
      .fontSize(18)
      .font("Helvetica-Bold")
      .text("TAX INVOICE", 360, 48, {
        width: 187,
        align: "right",
      });

    doc
      .fontSize(9)
      .font("Helvetica")
      .text(`Invoice No: ${invoice.invoiceNumber}`, 360, 76, {
        width: 187,
        align: "right",
      });

    doc
      .text(
        `Invoice Date: ${
          invoice.issuedAt
            ? invoice.issuedAt.toISOString().slice(0, 10)
            : new Date().toISOString().slice(0, 10)
        }`,
        360,
        90,
        {
          width: 187,
          align: "right",
        },
      );

    doc
      .moveTo(48, 122)
      .lineTo(pageWidth - 48, 122)
      .stroke();

    doc
      .fontSize(10)
      .font("Helvetica-Bold")
      .text("Bill To", 48, 143);

    let customerY = 161;

    doc
      .fontSize(10)
      .font("Helvetica-Bold")
      .text(invoice.customerLegalName, 48, customerY);

    customerY += 15;

    if (invoice.customerDisplayName) {
      doc
        .font("Helvetica")
        .text(invoice.customerDisplayName, 48, customerY);
      customerY += 14;
    }

    const addressParts = [
      invoice.customerAddressLine1,
      invoice.customerAddressLine2,
      [invoice.customerCity, invoice.customerState]
        .filter(Boolean)
        .join(", "),
      invoice.customerPostalCode,
      invoice.customerCountry,
    ]
      .map(safeText)
      .filter(Boolean);

    if (addressParts.length > 0) {
      doc
        .font("Helvetica")
        .fontSize(9)
        .text(addressParts.join("\n"), 48, customerY, {
          width: 230,
          lineGap: 2,
        });

      customerY += Math.max(30, addressParts.length * 13);
    }

    if (invoice.customerGstin) {
      doc
        .font("Helvetica")
        .fontSize(9)
        .text(`GSTIN: ${invoice.customerGstin}`, 48, customerY);
      customerY += 13;
    }

    if (invoice.customerPan) {
      doc
        .text(`PAN: ${invoice.customerPan}`, 48, customerY);
      customerY += 13;
    }

    if (invoice.customerBillingEmail) {
      doc
        .text(`Email: ${invoice.customerBillingEmail}`, 48, customerY);
      customerY += 13;
    }

    if (invoice.customerBillingPhone) {
      doc
        .text(`Phone: ${invoice.customerBillingPhone}`, 48, customerY);
    }

    const tableTop = Math.max(customerY + 35, 270);

    doc
      .fontSize(9)
      .font("Helvetica-Bold")
      .text("Description", 48, tableTop);

    doc.text("Qty", 330, tableTop, { width: 35, align: "right" });
    doc.text("Taxable", 370, tableTop, { width: 70, align: "right" });
    doc.text("GST", 445, tableTop, { width: 45, align: "right" });
    doc.text("Total", 495, tableTop, { width: 52, align: "right" });

    doc
      .moveTo(48, tableTop + 17)
      .lineTo(pageWidth - 48, tableTop + 17)
      .stroke();

    let rowY = tableTop + 29;

    for (const item of items) {
      doc
        .font("Helvetica")
        .fontSize(8.5)
        .text(item.description, 48, rowY, {
          width: 265,
        });

      doc.text(String(item.quantity), 330, rowY, {
        width: 35,
        align: "right",
      });

      doc.text(money(item.taxableAmountPaise, invoice.currency), 370, rowY, {
        width: 70,
        align: "right",
      });

      doc.text(
        `${item.gstPercent}%`,
        445,
        rowY,
        {
          width: 45,
          align: "right",
        },
      );

      doc.text(money(item.totalPaise, invoice.currency), 495, rowY, {
        width: 52,
        align: "right",
      });

      rowY += 30;
    }

    if (items.length === 0) {
      doc
        .font("Helvetica")
        .fontSize(9)
        .text("No invoice line items found.", 48, rowY);

      rowY += 30;
    }

    doc
      .moveTo(48, rowY)
      .lineTo(pageWidth - 48, rowY)
      .stroke();

    const summaryY = rowY + 22;

    doc
      .font("Helvetica")
      .fontSize(10)
      .text("Subtotal", 365, summaryY);

    doc.text(money(invoice.subtotalPaise, invoice.currency), 475, summaryY, {
      width: 72,
      align: "right",
    });

    doc
      .text("GST", 365, summaryY + 20);

    doc.text(money(invoice.gstPaise, invoice.currency), 475, summaryY + 20, {
      width: 72,
      align: "right",
    });

    doc
      .font("Helvetica-Bold")
      .fontSize(11)
      .text("Grand Total", 365, summaryY + 47);

    doc.text(money(invoice.totalPaise, invoice.currency), 475, summaryY + 47, {
      width: 72,
      align: "right",
    });

    doc
      .font("Helvetica")
      .fontSize(8)
      .text(
        "This is a system-generated invoice. Please retain this document for your records.",
        48,
        730,
        {
          width: contentWidth,
          align: "center",
        },
      );

    doc.end();
  });
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

    if (invoice.pdfStorageKey) {
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
      `${invoice.invoiceNumber}.pdf`,
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
