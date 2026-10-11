import { prisma } from "../../config/prisma.js";

type LookupRow = {
  id: string;
  companyId: string;
  warehouseId: string;
  externalOrderId: string;
  marketplaceOrderId: string | null;
  marketplace: string;
  orderStatus: string;
  orderDate: Date;
  shipmentId: string | null;
  awb: string | null;
  carrier: string | null;
  shipmentStatus: string | null;
  items: unknown;
};

type LookupType = "BARCODE" | "AWB" | "ORDER_ID" | "SKU";

function parseItems(value: unknown) {
  if (!Array.isArray(value)) return [];

  return value.map((raw: any, index: number) => ({
    id: String(raw.id ?? `item-${index + 1}`),
    sku: raw.sku ?? null,
    productName: raw.productName ?? "Unknown Product",
    quantity: Number(raw.quantity ?? 0),
    variant: raw.variantName ?? null,
    product: {
      id: raw.productId ?? null,
      sku: raw.sku ?? null,
      name: raw.productName ?? "Unknown Product",
      imageUrl: raw.imageUrl ?? null,
    },
    status: null,
    scannedQty: 0,
  }));
}

export class ScanService {
  private normalize(value: string) {
    return String(value ?? "").trim();
  }

  private async findOrder(
    companyId: string,
    value: string,
    mode: "identifier" | "order" | "sku",
  ): Promise<LookupRow[]> {
    const needle = this.normalize(value);
    if (!needle) return [];

    const identifierPredicate = `
      (
        lower(trim(s.awb)) = lower(trim($2))
        OR EXISTS (
          SELECT 1
          FROM public.shipment_barcodes sb
          WHERE sb."shipmentId" = s.id
            AND sb."isActive" = TRUE
            AND lower(trim(sb.barcode)) = lower(trim($2))
        )
        OR EXISTS (
          SELECT 1
          FROM public.barcode_aliases ba
          WHERE ba."isActive" = TRUE
            AND lower(trim(ba.barcode)) = lower(trim($2))
            AND (
              ba."productId" IN (
                SELECT oi."productId"
                FROM public.order_items oi
                WHERE oi."orderId" = o.id
              )
              OR ba."variantId" IN (
                SELECT oi."variantId"
                FROM public.order_items oi
                WHERE oi."orderId" = o.id
                  AND oi."variantId" IS NOT NULL
              )
            )
        )
      )
    `;

    const orderPredicate = `
      (
        o.id = $2
        OR lower(trim(o."externalOrderId")) = lower(trim($2))
        OR lower(trim(coalesce(o."marketplaceOrderId", ''))) = lower(trim($2))
      )
    `;

    const skuPredicate = `
      EXISTS (
        SELECT 1
        FROM public.order_items oi
        JOIN public.products p ON p.id = oi."productId"
        LEFT JOIN public.product_variants pv ON pv.id = oi."variantId"
        WHERE oi."orderId" = o.id
          AND (
            lower(trim(p.sku)) = lower(trim($2))
            OR lower(trim(coalesce(pv.sku, ''))) = lower(trim($2))
            OR EXISTS (
              SELECT 1
              FROM public.barcode_aliases ba
              WHERE ba."isActive" = TRUE
                AND lower(trim(ba.barcode)) = lower(trim($2))
                AND (
                  ba."productId" = p.id
                  OR ba."variantId" = pv.id
                )
            )
          )
      )
    `;

    const predicate =
      mode === "identifier"
        ? identifierPredicate
        : mode === "order"
          ? orderPredicate
          : skuPredicate;

    return prisma.$queryRawUnsafe<LookupRow[]>(
      `
      SELECT
        o.id,
        o."companyId",
        o."warehouseId",
        o."externalOrderId",
        o."marketplaceOrderId",
        o.marketplace::text AS marketplace,
        o.status::text AS "orderStatus",
        o."orderedAt" AS "orderDate",
        s.id AS "shipmentId",
        s.awb,
        s.carrier,
        s.status::text AS "shipmentStatus",
        COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', oi.id,
                'productId', p.id,
                'sku', COALESCE(pv.sku, p.sku),
                'productName', p.name,
                'imageUrl', COALESCE(pv."imageUrl", p."imageUrl"),
                'quantity', oi.quantity,
                'variantName', pv."variantName"
              )
              ORDER BY oi."createdAt", oi.id
            )
            FROM public.order_items oi
            JOIN public.products p ON p.id = oi."productId"
            LEFT JOIN public.product_variants pv ON pv.id = oi."variantId"
            WHERE oi."orderId" = o.id
          ),
          '[]'::jsonb
        ) AS items
      FROM public.orders o
      LEFT JOIN public.shipments s ON s."orderId" = o.id
      WHERE o."companyId" = $1
        AND ${predicate}
      ORDER BY
        CASE WHEN s.id IS NOT NULL THEN 0 ELSE 1 END,
        o."createdAt" DESC
      LIMIT 20
      `,
      companyId,
      needle,
    );
  }

  private buildLookupResponse(
    row: LookupRow,
    lookupType: LookupType,
    matchedIdentifier: string | null = null,
  ) {
    return {
      found: true,
      lookupType,
      shipment: {
        id: row.shipmentId ?? row.id,
        awb: row.awb,
        carrier: row.carrier,
        status: row.shipmentStatus ?? row.orderStatus,
        barcodes: matchedIdentifier ? [matchedIdentifier] : [],
      },
      order: {
        id: row.id,
        externalOrderId: row.externalOrderId,
        marketplaceOrderId: row.marketplaceOrderId,
        marketplace: row.marketplace,
        status: row.orderStatus,
        orderDate: row.orderDate,
        warehouseId: row.warehouseId,
      },
      items: parseItems(row.items),
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

    const identifiers = await this.findOrder(companyId, normalized, "identifier");

    if (identifiers.length > 0) {
      const row = identifiers[0];
      const lookupType: LookupType =
        row.awb && row.awb.toLowerCase() === normalized.toLowerCase()
          ? "AWB"
          : "BARCODE";

      return this.buildLookupResponse(row, lookupType, normalized);
    }

    const byOrder = await this.findOrder(companyId, normalized, "order");

    if (byOrder.length > 0) {
      return this.buildLookupResponse(byOrder[0], "ORDER_ID");
    }

    const bySku = await this.findOrder(companyId, normalized, "sku");

    if (bySku.length > 1) {
      return {
        found: false,
        lookupType: "SKU",
        message:
          "SKU matches multiple orders. Scan the shipment barcode or AWB instead.",
      };
    }

    if (bySku.length === 1) {
      return this.buildLookupResponse(bySku[0], "SKU");
    }

    return {
      found: false,
      lookupType: null,
      message: "Barcode, AWB, order ID or SKU was not found.",
    };
  }
}

export const scanService = new ScanService();
