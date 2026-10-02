import { prisma } from "../../config/prisma.js";

type LiveOrder = {
  id: string;
  companyId: string;
  warehouseId: string | null;
  marketplace: string | null;
  marketplaceOrderId: string | null;
  status: string | null;
  awb: string | null;
  courier: string | null;
  items: any;
  metadata: any;
  createdAt: Date;
};

export class ScanService {
  private normalize(value: string) {
    return value.trim();
  }

  private async findOrderByIdentifier(companyId: string, value: string) {
    const normalized = this.normalize(value);

    const directAwb = await prisma.$queryRawUnsafe<LiveOrder[]>(
      `SELECT
        o.id,
        o."companyId",
        o."warehouseId",
        o.marketplace,
        o."marketplaceOrderId",
        o.status,
        o.awb,
        o.courier,
        o.items,
        o.metadata,
        o."createdAt"
       FROM "Order" o
       WHERE o."companyId" = $1
         AND lower(trim(coalesce(o.awb, ''))) = lower(trim($2))
       LIMIT 1`,
      companyId,
      normalized,
    );

    if (directAwb.length) {
      return {
        order: directAwb[0],
        lookupType: "AWB" as const,
      };
    }

    const identifierRows = await prisma.$queryRawUnsafe<
      { order_id: string; identifier_type: string }[]
    >(
      `SELECT oi.order_id, oi.identifier_type
       FROM order_identifiers oi
       WHERE oi.company_id = $1
         AND (
           lower(trim(coalesce(oi.normalized_value, ''))) = lower(trim($2))
           OR lower(trim(coalesce(oi.identifier_value, ''))) = lower(trim($2))
         )
       ORDER BY
         CASE
           WHEN oi.identifier_type = 'awb' THEN 1
           WHEN oi.identifier_type = 'barcode' THEN 2
           WHEN oi.identifier_type = 'order_id' THEN 3
           ELSE 4
         END,
         oi.created_at DESC
       LIMIT 1`,
      companyId,
      normalized,
    );

    if (!identifierRows.length) {
      return null;
    }

    const orderRows = await prisma.$queryRawUnsafe<LiveOrder[]>(
      `SELECT
        o.id,
        o."companyId",
        o."warehouseId",
        o.marketplace,
        o."marketplaceOrderId",
        o.status,
        o.awb,
        o.courier,
        o.items,
        o.metadata,
        o."createdAt"
       FROM "Order" o
       WHERE o.id = $1
         AND o."companyId" = $2
       LIMIT 1`,
      identifierRows[0].order_id,
      companyId,
    );

    if (!orderRows.length) {
      return null;
    }

    const type = identifierRows[0].identifier_type;

    return {
      order: orderRows[0],
      lookupType:
        type === "awb"
          ? ("AWB" as const)
          : type === "order_id"
            ? ("ORDER_ID" as const)
            : ("BARCODE" as const),
    };
  }

  private async findOrderByOrderId(companyId: string, value: string) {
    const rows = await prisma.$queryRawUnsafe<LiveOrder[]>(
      `SELECT
        o.id,
        o."companyId",
        o."warehouseId",
        o.marketplace,
        o."marketplaceOrderId",
        o.status,
        o.awb,
        o.courier,
        o.items,
        o.metadata,
        o."createdAt"
       FROM "Order" o
       WHERE o."companyId" = $1
         AND (
           o.id::text = $2
           OR lower(trim(coalesce(o."marketplaceOrderId", ''))) = lower(trim($2))
         )
       LIMIT 1`,
      companyId,
      value,
    );

    return rows[0] ?? null;
  }

  private parseItems(order: LiveOrder) {
    if (!Array.isArray(order.items)) {
      return [];
    }

    return order.items.map((item: any, index: number) => ({
      id: `${order.id}-item-${index + 1}`,
      sku: item?.sku ?? null,
      productName: item?.name ?? "Unknown Product",
      quantity: Number(item?.qty ?? item?.quantity ?? 0),
      variant: null,
      product: {
        id: null,
        sku: item?.sku ?? null,
        name: item?.name ?? "Unknown Product",
        imageUrl: item?.imageUrl ?? null,
      },
      status: item?.status ?? null,
      scannedQty: Number(item?.scannedQty ?? 0),
    }));
  }

  private buildLookupResponse(
    order: LiveOrder,
    lookupType: "BARCODE" | "AWB" | "ORDER_ID" | "SKU",
    matchedIdentifier?: string | null,
  ) {
    const items = this.parseItems(order);

    const barcodes = matchedIdentifier
      ? [matchedIdentifier]
      : [];

    return {
      found: true,
      lookupType,
      shipment: {
        id: order.id,
        awb: order.awb,
        carrier: order.courier,
        status: order.status,
        barcodes,
      },
      order: {
        id: order.id,
        externalOrderId: order.id,
        marketplaceOrderId: order.marketplaceOrderId,
        marketplace: order.marketplace,
        status: order.status,
        orderDate: order.createdAt,
      },
      items,
    };
  }

  async lookup(companyId: string, barcode: string) {
    const normalized = this.normalize(barcode);

    if (!normalized) {
      return {
        found: false,
        lookupType: null,
        message: "Barcode is required.",
      };
    }

    const identifierResult = await this.findOrderByIdentifier(
      companyId,
      normalized,
    );

    if (identifierResult) {
      return this.buildLookupResponse(
        identifierResult.order,
        identifierResult.lookupType,
        normalized,
      );
    }

    const orderById = await this.findOrderByOrderId(
      companyId,
      normalized,
    );

    if (orderById) {
      return this.buildLookupResponse(
        orderById,
        "ORDER_ID",
        null,
      );
    }

    const skuOrders = await prisma.$queryRawUnsafe<LiveOrder[]>(
      `SELECT
        o.id,
        o."companyId",
        o."warehouseId",
        o.marketplace,
        o."marketplaceOrderId",
        o.status,
        o.awb,
        o.courier,
        o.items,
        o.metadata,
        o."createdAt"
       FROM "Order" o
       WHERE o."companyId" = $1
         AND o.status IN (
           'queued',
           'synced',
           'packing',
           'evidence_ready'
         )
         AND EXISTS (
           SELECT 1
           FROM jsonb_array_elements(
             CASE
               WHEN jsonb_typeof(o.items) = 'array' THEN o.items
               ELSE '[]'::jsonb
             END
           ) item
           WHERE lower(trim(coalesce(item->>'sku', ''))) =
                 lower(trim($2))
         )
       ORDER BY o."createdAt" DESC`,
      companyId,
      normalized,
    );

    if (skuOrders.length > 1) {
      return {
        found: false,
        lookupType: "SKU",
        message:
          "SKU is ambiguous. Please scan the shipping barcode or AWB instead.",
      };
    }

    if (skuOrders.length === 1) {
      return this.buildLookupResponse(
        skuOrders[0],
        "SKU",
        null,
      );
    }

    return {
      found: false,
      lookupType: null,
      message: "Barcode, AWB, order ID or SKU was not found.",
    };
  }
}

export const scanService = new ScanService();


