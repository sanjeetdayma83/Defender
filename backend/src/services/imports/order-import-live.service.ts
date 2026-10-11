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
  orderDate?: Date;
};

export type LiveImportValidation = {
  valid: boolean;
  rows: LiveImportRow[];
  duplicates: Array<{ rowNumber: number }>;
  issues: unknown[];
};

type IdRow = { id: string };
type ExistingOrderRow = { id: string };
type ExistingShipmentRow = { id: string; orderId: string };

function normalizeMarketplace(value: unknown): "AMAZON" | "FLIPKART" | "MEESHO" | "OTHER" {
  const raw = String(value ?? "").trim().toLowerCase();

  if (raw.includes("flipkart") || raw === "fk") return "FLIPKART";
  if (raw.includes("meesho")) return "MEESHO";
  if (raw.includes("amazon") || raw === "amz") return "AMAZON";

  // These are the marketplace labels present in the live PostgreSQL enum.
  return "OTHER";
}

function clean(value: unknown): string {
  return String(value ?? "").trim();
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

    if (!clean(companyId) || !clean(warehouseId)) {
      throw new Error("COMPANY_AND_WAREHOUSE_REQUIRED");
    }

    const duplicateRows = new Set(
      validation.duplicates.map((duplicate) => duplicate.rowNumber),
    );

    const result = {
      totalRows: validation.rows.length,
      importedRows: 0,
      createdOrders: 0,
      updatedOrders: 0,
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

    await prisma.$transaction(async (tx) => {
      const warehouses = await tx.$queryRawUnsafe<IdRow[]>(
        `SELECT id
           FROM warehouses
          WHERE id = $1
            AND "companyId" = $2
            AND "isActive" = TRUE
          LIMIT 1`,
        warehouseId,
        companyId,
      );

      if (!warehouses[0]) {
        throw new Error("WAREHOUSE_NOT_FOUND_OR_INACTIVE");
      }

      for (const row of validation.rows) {
        if (duplicateRows.has(row.rowNumber)) continue;

        const orderIdFromFile = clean(row.orderId);
        const awb = clean(row.awb);
        const sku = clean(row.sku);
        const productName = clean(row.productName);

        if (
          !orderIdFromFile ||
          !awb ||
          !sku ||
          !productName ||
          !Number.isInteger(row.quantity) ||
          row.quantity <= 0
        ) {
          throw new Error(`INVALID_IMPORT_ROW:${row.rowNumber}`);
        }

        const marketplace = normalizeMarketplace(row.marketplace);

        // Find or create a company-scoped product.
        const products = await tx.$queryRawUnsafe<IdRow[]>(
          `SELECT id
             FROM products
            WHERE "companyId" = $1
              AND lower(trim(sku)) = lower(trim($2))
            LIMIT 1`,
          companyId,
          sku,
        );

        let productId: string;

        if (products[0]) {
          productId = products[0].id;

          await tx.$executeRawUnsafe(
            `UPDATE products
                SET name = $1,
                    "imageUrl" = COALESCE($2, "imageUrl"),
                    "isActive" = TRUE,
                    "updatedAt" = CURRENT_TIMESTAMP
              WHERE id = $3
                AND "companyId" = $4`,
            productName,
            row.imageUrl ?? null,
            productId,
            companyId,
          );

          result.updatedProducts += 1;
        } else {
          productId = randomUUID();

          await tx.$executeRawUnsafe(
            `INSERT INTO products (
               id, sku, name, "imageUrl", "isActive", "companyId",
               "createdAt", "updatedAt"
             ) VALUES ($1, $2, $3, $4, TRUE, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
            productId,
            sku,
            productName,
            row.imageUrl ?? null,
            companyId,
          );

          result.createdProducts += 1;
        }

        const variantName = clean(row.variant);
        const color = clean(row.color);
        const size = clean(row.size);
        const hasVariant = Boolean(variantName || color || size);
        let variantId: string | null = null;

        if (hasVariant) {
          const variantKey = [variantName, color, size]
            .filter(Boolean)
            .join("|");
          const variantSku = `${sku}::${variantKey}`;

          const variants = await tx.$queryRawUnsafe<IdRow[]>(
            `SELECT id
               FROM product_variants
              WHERE "productId" = $1
                AND lower(trim(sku)) = lower(trim($2))
              LIMIT 1`,
            productId,
            variantSku,
          );

          if (variants[0]) {
            variantId = variants[0].id;

            await tx.$executeRawUnsafe(
              `UPDATE product_variants
                  SET name = $1,
                      "variantName" = $2,
                      color = $3,
                      size = $4,
                      "imageUrl" = COALESCE($5, "imageUrl"),
                      "isActive" = TRUE,
                      "updatedAt" = CURRENT_TIMESTAMP
                WHERE id = $6`,
              variantName || productName,
              variantName || null,
              color || null,
              size || null,
              row.imageUrl ?? null,
              variantId,
            );

            result.updatedVariants += 1;
          } else {
            variantId = randomUUID();

            await tx.$executeRawUnsafe(
              `INSERT INTO product_variants (
                 id, sku, name, "variantName", color, size, "imageUrl",
                 quantity, "isActive", "productId", "createdAt", "updatedAt"
               ) VALUES (
                 $1, $2, $3, $4, $5, $6, $7, 0, TRUE, $8,
                 CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
               )`,
              variantId,
              variantSku,
              variantName || productName,
              variantName || null,
              color || null,
              size || null,
              row.imageUrl ?? null,
              productId,
            );

            result.createdVariants += 1;
          }
        }

        // Reuse an order for additional SKU rows belonging to the same order.
        const orders = await tx.$queryRawUnsafe<ExistingOrderRow[]>(
          `SELECT id
             FROM orders
            WHERE "companyId" = $1
              AND marketplace = $2::"Marketplace"
              AND (
                "marketplaceOrderId" = $3
                OR (
                  "marketplaceOrderId" IS NULL
                  AND "externalOrderId" = $3
                )
              )
            ORDER BY "createdAt" DESC
            LIMIT 1`,
          companyId,
          marketplace,
          orderIdFromFile,
        );

        let orderId: string;

        if (orders[0]) {
          orderId = orders[0].id;

          await tx.$executeRawUnsafe(
            `UPDATE orders
                SET "warehouseId" = $1,
                    "marketplaceOrderId" = $2,
                    "customerName" = COALESCE($3, "customerName"),
                    "orderedAt" = COALESCE($4, "orderedAt"),
                    "updatedAt" = CURRENT_TIMESTAMP
              WHERE id = $5
                AND "companyId" = $6`,
            warehouseId,
            orderIdFromFile,
            clean(row.customerName) || null,
            row.orderDate ?? null,
            orderId,
            companyId,
          );

          result.updatedOrders += 1;
        } else {
          orderId = randomUUID();

          await tx.$executeRawUnsafe(
            `INSERT INTO orders (
               id, "externalOrderId", "marketplaceOrderId", marketplace,
               status, "customerName", "warehouseId", "companyId",
               "orderedAt", "createdAt", "updatedAt"
             ) VALUES (
               $1, $2, $3, $4::"Marketplace", 'PENDING'::"OrderStatus",
               $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
             )`,
            orderId,
            orderIdFromFile,
            orderIdFromFile,
            marketplace,
            clean(row.customerName) || null,
            warehouseId,
            companyId,
            row.orderDate ?? null,
          );

          result.createdOrders += 1;
        }

        // The AWB must not be silently reassigned to another order.
        const shipments = await tx.$queryRawUnsafe<ExistingShipmentRow[]>(
          `SELECT id, "orderId"
             FROM shipments
            WHERE lower(trim(awb)) = lower(trim($1))
            LIMIT 1`,
          awb,
        );

        let shipmentId: string;

        if (shipments[0]) {
          if (shipments[0].orderId !== orderId) {
            throw new Error(`AWB_ALREADY_ASSIGNED:${awb}`);
          }

          shipmentId = shipments[0].id;

          await tx.$executeRawUnsafe(
            `UPDATE shipments
                SET status = 'READY_TO_PACK'::"ShipmentStatus",
                    "updatedAt" = CURRENT_TIMESTAMP
              WHERE id = $1`,
            shipmentId,
          );

          result.updatedShipments += 1;
        } else {
          shipmentId = randomUUID();

          await tx.$executeRawUnsafe(
            `INSERT INTO shipments (
               id, awb, status, "orderId", "createdAt", "updatedAt"
             ) VALUES (
               $1, $2, 'READY_TO_PACK'::"ShipmentStatus", $3,
               CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
             )`,
            shipmentId,
            awb,
            orderId,
          );

          result.createdShipments += 1;
        }

        // Store the AWB in the canonical shipment barcode table.
        const barcodeRows = await tx.$queryRawUnsafe<
          Array<{ id: string; shipmentId: string }>
        >(
          `SELECT id, "shipmentId"
             FROM shipment_barcodes
            WHERE lower(trim(barcode)) = lower(trim($1))
            LIMIT 1`,
          awb,
        );

        if (barcodeRows[0] && barcodeRows[0].shipmentId !== shipmentId) {
          throw new Error(`BARCODE_ALREADY_ASSIGNED:${awb}`);
        }

        if (barcodeRows[0]) {
          await tx.$executeRawUnsafe(
            `UPDATE shipment_barcodes
                SET type = 'AWB', "isActive" = TRUE
              WHERE id = $1`,
            barcodeRows[0].id,
          );
        } else {
          await tx.$executeRawUnsafe(
            `INSERT INTO shipment_barcodes (
               id, barcode, type, "isActive", "shipmentId", "createdAt"
             ) VALUES ($1, $2, 'AWB', TRUE, $3, CURRENT_TIMESTAMP)`,
            randomUUID(),
            awb,
            shipmentId,
          );
        }

        const existingItems = await tx.$queryRawUnsafe<IdRow[]>(
          `SELECT id
             FROM order_items
            WHERE "orderId" = $1
              AND "productId" = $2
              AND "variantId" IS NOT DISTINCT FROM $3
            LIMIT 1`,
          orderId,
          productId,
          variantId,
        );

        if (existingItems[0]) {
          await tx.$executeRawUnsafe(
            `UPDATE order_items
                SET quantity = $1,
                    "updatedAt" = CURRENT_TIMESTAMP
              WHERE id = $2`,
            row.quantity,
            existingItems[0].id,
          );

          result.updatedOrderItems += 1;
        } else {
          await tx.$executeRawUnsafe(
            `INSERT INTO order_items (
               id, quantity, "orderId", "productId", "variantId",
               "createdAt", "updatedAt"
             ) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
            randomUUID(),
            row.quantity,
            orderId,
            productId,
            variantId,
          );

          result.createdOrderItems += 1;
        }

        result.importedRows += 1;
      }
    }, {
      timeout: 30000,
      maxWait: 10000,
    });

    return result;
  }
}

export const orderImportLiveService = new OrderImportLiveService();