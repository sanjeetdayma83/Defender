import { randomUUID } from "node:crypto";
import { prisma } from "../../config/prisma.js";

export type LiveImportRow = {
  rowNumber: number;
  orderId: string;
  awb: string;
  sku: string;
  productName: string;
  quantity: number;
  variant?: string | null;
  color?: string | null;
  size?: string | null;
  marketplace: string;
  customerName?: string | null;
  imageUrl?: string | null;
};

export type LiveImportValidation = {
  valid: boolean;
  rows: LiveImportRow[];
  duplicates: Array<{ rowNumber: number }>;
  issues: unknown[];
};

function mapMarketplace(value: unknown): string {
  const raw = String(value ?? "").trim().toLowerCase();
  // Live PG enum labels (discovered / common legacy set)
  if (raw.includes("flipkart") || raw === "fk") return "flipkart";
  if (raw.includes("meesho")) return "meesho";
  if (raw.includes("amazon") || raw === "amz") return "amazon";
  if (raw.includes("myntra")) return "myntra";
  if (raw.includes("shopify")) return "shopify";
  // Safe default — must exist in enum; change after label query if needed
  return "amazon";
}

export class OrderImportLiveService {
  async import(
    companyId: string,
    warehouseId: string,
    validation: LiveImportValidation,
  ) {
    if (!validation.valid) {
      throw new Error("IMPORT_VALIDATION_FAILED");
    }

    const wh = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
      `SELECT id FROM "Warehouse" WHERE id = $1 AND "companyId" = $2 LIMIT 1`,
      warehouseId,
      companyId,
    );

    if (!wh[0]) {
      throw new Error("WAREHOUSE_NOT_FOUND");
    }

    const skip = new Set(validation.duplicates.map((d) => d.rowNumber));
    let importedRows = 0;
    let createdOrders = 0;
    let updatedOrders = 0;

    for (const row of validation.rows) {
      if (skip.has(row.rowNumber)) continue;

      const itemsJson = JSON.stringify([
        {
          sku: row.sku,
          name: row.productName,
          qty: row.quantity,
          quantity: row.quantity,
          variant: row.variant ?? null,
          color: row.color ?? null,
          size: row.size ?? null,
          imageUrl: row.imageUrl ?? null,
          scannedQty: 0,
          status: "pending",
        },
      ]);

      const marketplace = mapMarketplace(row.marketplace);

      const existing = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
        `SELECT id FROM "Order"
         WHERE "companyId" = $1
           AND lower(trim(coalesce(awb, ''))) = lower(trim($2))
         LIMIT 1`,
        companyId,
        row.awb,
      );

      let orderId: string;

      if (existing[0]) {
        orderId = existing[0].id;
        await prisma.$executeRawUnsafe(
          `UPDATE "Order"
           SET "warehouseId" = $1,
               marketplace = $2::"Marketplace",
               "marketplaceOrderId" = $3,
               status = 'queued',
               items = $4::jsonb,
               "updatedAt" = CURRENT_TIMESTAMP
           WHERE id = $5 AND "companyId" = $6`,
          warehouseId,
          marketplace,
          row.orderId,
          itemsJson,
          orderId,
          companyId,
        );
        updatedOrders += 1;
      } else {
        orderId = randomUUID();
        await prisma.$executeRawUnsafe(
          `INSERT INTO "Order" (
             id, "companyId", "warehouseId", marketplace, "marketplaceOrderId",
             status, awb, courier, items, metadata, "createdAt", "updatedAt"
           ) VALUES (
             $1, $2, $3, $4::"Marketplace", $5,
             'queued', $6, NULL, $7::jsonb, '{}'::jsonb,
             CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
           )`,
          orderId,
          companyId,
          warehouseId,
          marketplace,
          row.orderId,
          row.awb,
          itemsJson,
        );
        createdOrders += 1;
      }

      const idents = [
        { type: "awb", value: row.awb },
        { type: "order_id", value: row.orderId },
        { type: "barcode", value: row.awb },
      ];

      for (const ident of idents) {
        const val = String(ident.value ?? "").trim();
        if (!val) continue;

        const found = await prisma.$queryRawUnsafe<Array<{ id: string; order_id: string }>>(
          `SELECT id::text AS id, order_id::text AS order_id
           FROM order_identifiers
           WHERE company_id = $1
             AND identifier_type = $2
             AND lower(trim(coalesce(normalized_value, identifier_value, ''))) = lower(trim($3))
           LIMIT 1`,
          companyId,
          ident.type,
          val,
        );

        if (found[0] && found[0].order_id !== orderId) {
          throw new Error(
            `IDENTIFIER_CONFLICT:${ident.type}:${val}`,
          );
        }

        if (!found[0]) {
          await prisma.$executeRawUnsafe(
            `INSERT INTO order_identifiers (
               id, company_id, order_id, identifier_type,
               identifier_value, normalized_value, created_at
             ) VALUES (
               $1::uuid, $2, $3, $4, $5, lower(trim($5)), CURRENT_TIMESTAMP
             )`,
            randomUUID(),
            companyId,
            orderId,
            ident.type,
            val,
          );
        }
      }

      importedRows += 1;
    }

    return {
      totalRows: validation.rows.length,
      importedRows,
      createdOrders,
      updatedOrders,
      createdProducts: 0,
      updatedProducts: 0,
      createdVariants: 0,
      updatedVariants: 0,
      createdShipments: 0,
      updatedShipments: 0,
      createdOrderItems: 0,
      updatedOrderItems: 0,
      duplicateRows: validation.duplicates.length,
      errorRows: validation.issues.length,
      issues: validation.issues,
    };
  }
}

export const orderImportLiveService = new OrderImportLiveService();
