import { prisma } from "../../config/prisma.js";

type LiveOrderRow = {
  id: string;
  companyId: string;
  warehouseId: string | null;
  marketplace: string | null;
  marketplaceOrderId: string | null;
  status: string | null;
  awb: string | null;
  courier: string | null;
  items: unknown;
  metadata: unknown;
  createdAt: Date;
};

function parseItems(items: unknown) {
  if (!Array.isArray(items)) return [];
  return items.map((item: any, index: number) => {
    const sku = item?.sku ?? null;
    const name = item?.name ?? item?.productName ?? "Unknown Product";
    const quantity = Number(item?.qty ?? item?.quantity ?? 1) || 1;
    return {
      id: `item-${index + 1}`,
      sku,
      quantity,
      productName: name,
      product: { id: null, sku, name, imageUrl: item?.imageUrl ?? null },
      variant: {
        name: item?.variant ?? item?.variantName ?? "Standard",
        color: item?.color ?? null,
        size: item?.size ?? null,
        sku,
      },
    };
  });
}

function mapLiveOrder(row: LiveOrderRow) {
  return {
    id: row.id,
    companyId: row.companyId,
    warehouseId: row.warehouseId,
    externalOrderId: row.marketplaceOrderId ?? row.id,
    marketplaceOrderId: row.marketplaceOrderId,
    marketplace: row.marketplace ?? "OTHER",
    status: row.status ?? "PENDING",
    customerName: null,
    createdAt: row.createdAt,
    warehouse: row.warehouseId ? { id: row.warehouseId } : null,
    shipments: [{ id: row.id, awb: row.awb, carrier: row.courier, status: row.status }],
    items: parseItems(row.items),
  };
}

export class DatabaseOrderService {
  async list(companyId: string, search?: string, status?: string) {
    const normalizedSearch = search?.trim() ?? "";
    const normalizedStatus = status?.trim() ?? "";
    const rows = await prisma.$queryRawUnsafe<LiveOrderRow[]>(
      `
        SELECT o.id, o."companyId", o."warehouseId", o.marketplace,
               o."marketplaceOrderId", o.status, o.awb, o.courier,
               o.items, o.metadata, o."createdAt"
        FROM "Order" o
        WHERE o."companyId" = $1
          AND ($2::text = '' OR o.status ILIKE $2)
          AND (
            $3::text = ''
            OR lower(trim(coalesce(o.awb, ''))) LIKE lower('%' || $3 || '%')
            OR lower(trim(coalesce(o."marketplaceOrderId", ''))) LIKE lower('%' || $3 || '%')
            OR lower(trim(coalesce(o.id::text, ''))) LIKE lower('%' || $3 || '%')
            OR lower(coalesce(o.items::text, '')) LIKE lower('%' || $3 || '%')
          )
        ORDER BY o."createdAt" DESC
        LIMIT 100
      `,
      companyId, normalizedStatus, normalizedSearch,
    );
    return rows.map(mapLiveOrder);
  }

  async get(companyId: string, id: string) {
    const rows = await prisma.$queryRawUnsafe<LiveOrderRow[]>(
      `
        SELECT o.id, o."companyId", o."warehouseId", o.marketplace,
               o."marketplaceOrderId", o.status, o.awb, o.courier,
               o.items, o.metadata, o."createdAt"
        FROM "Order" o
        WHERE o.id = $1 AND o."companyId" = $2
        LIMIT 1
      `,
      id, companyId,
    );
    return rows[0] ? mapLiveOrder(rows[0]) : null;
  }
}

export const databaseOrderService = new DatabaseOrderService();
