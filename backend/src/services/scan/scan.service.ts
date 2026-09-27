import { OrderStatus } from "../../generated/prisma/client.js";
import { prisma } from "../../config/prisma.js";

export class ScanService {
  async lookup(companyId: string, barcode: string) {
    const normalized = barcode.trim();

    if (!normalized) {
      throw new Error("Barcode is required.");
    }

    /*
     * ========================================================
     * 1. SHIPPING BARCODE
     * ========================================================
     *
     * ShipmentBarcode currently exposes shipmentId rather than
     * a nested shipment relation in the generated Prisma client.
     */
    const barcodeRecord = await prisma.shipmentBarcode.findFirst({
      where: {
        barcode: normalized,
      },
    });

    if (barcodeRecord) {
      const shipment = await prisma.shipment.findUnique({
        where: {
          id: barcodeRecord.shipmentId,
        },
      });

      if (shipment) {
        const order = await this.getCompanyOrder(companyId, shipment.orderId);

        if (order) {
          return this.buildLookupResponse(shipment, order);
        }
      }
    }

    /*
     * ========================================================
     * 2. AWB
     * ========================================================
     */
    const shipmentByAwb = await prisma.shipment.findFirst({
      where: {
        awb: normalized,
      },
    });

    if (shipmentByAwb) {
      const order = await this.getCompanyOrder(
        companyId,
        shipmentByAwb.orderId,
      );

      if (order) {
        return this.buildLookupResponse(shipmentByAwb, order);
      }
    }

    /*
     * ========================================================
     * 3. EXTERNAL / MARKETPLACE ORDER ID
     * ========================================================
     */
    const orderById = await prisma.order.findFirst({
      where: {
        companyId,
        OR: [
          {
            externalOrderId: normalized,
          },
          {
            marketplaceOrderId: normalized,
          },
        ],
      },
    });

    if (orderById) {
      const shipment = await prisma.shipment.findFirst({
        where: {
          orderId: orderById.id,
        },
      });

      if (!shipment) {
        throw new Error(
          "Order found, but no shipment is associated with this order.",
        );
      }

      return this.buildLookupResponse(shipment, orderById);
    }

    /*
     * ========================================================
     * 4. SKU
     * ========================================================
     *
     * OrderItem itself does not contain sku in the current
     * Prisma schema.
     *
     * SKU belongs to Product / ProductVariant, so resolve the
     * SKU there first.
     */
    const product = await prisma.product.findFirst({
      where: {
        companyId,
        sku: normalized,
      },
    });

    const variant = await prisma.productVariant.findFirst({
      where: {
        sku: normalized,
        product: {
          companyId,
        },
      },
    });

    const productIds: string[] = [];

    if (product) {
      productIds.push(product.id);
    }

    if (variant && !productIds.includes(variant.productId)) {
      productIds.push(variant.productId);
    }

    if (productIds.length > 0) {
      const orderItems = await prisma.orderItem.findMany({
        where: {
          productId: {
            in: productIds,
          },
          order: {
            companyId,
            status: {
              in: [
                OrderStatus.PENDING,
                OrderStatus.CONFIRMED,
                OrderStatus.PACKING,
                OrderStatus.PACKED,
              ],
            },
          },
        },
      });

      const uniqueOrderIds = Array.from(
        new Set(orderItems.map((item) => item.orderId)),
      );

      if (uniqueOrderIds.length > 1) {
        throw new Error(
          "SKU is ambiguous. Please scan the shipping barcode or AWB instead.",
        );
      }

      if (uniqueOrderIds.length === 1) {
        const skuOrder = await prisma.order.findFirst({
          where: {
            id: uniqueOrderIds[0],
            companyId,
          },
        });

        if (!skuOrder) {
          throw new Error("SKU order was not found.");
        }

        const shipment = await prisma.shipment.findFirst({
          where: {
            orderId: skuOrder.id,
          },
        });

        if (!shipment) {
          throw new Error(
            "SKU matched an order, but no shipment is associated with it.",
          );
        }

        return this.buildLookupResponse(shipment, skuOrder);
      }
    }

    throw new Error("Barcode, AWB, order ID or SKU was not found.");
  }

  private async getCompanyOrder(companyId: string, orderId: string) {
    return prisma.order.findFirst({
      where: {
        id: orderId,
        companyId,
      },
    });
  }

  private async buildLookupResponse(shipment: any, order: any) {
    const orderItems = await prisma.orderItem.findMany({
      where: {
        orderId: order.id,
      },
    });

    const productIds = Array.from(
      new Set(orderItems.map((item) => item.productId)),
    );

    const variantIds = Array.from(
      new Set(
        orderItems
          .map((item) => item.variantId)
          .filter((id): id is string => Boolean(id)),
      ),
    );

    const products =
      productIds.length > 0
        ? await prisma.product.findMany({
            where: {
              id: {
                in: productIds,
              },
            },
          })
        : [];

    const variants =
      variantIds.length > 0
        ? await prisma.productVariant.findMany({
            where: {
              id: {
                in: variantIds,
              },
            },
          })
        : [];

    const productMap = new Map(
      products.map((product) => [product.id, product]),
    );

    const variantMap = new Map(
      variants.map((variant) => [variant.id, variant]),
    );

    const shipmentBarcodes = await prisma.shipmentBarcode.findMany({
      where: {
        shipmentId: shipment.id,
      },
    });

    return {
      shipment: {
        id: shipment.id,
        awb: shipment.awb,
        carrier: shipment.carrier,
        status: shipment.status,
        barcodes: shipmentBarcodes.map((item) => item.barcode),
      },

      order: {
        id: order.id,
        externalOrderId: order.externalOrderId,
        marketplaceOrderId: order.marketplaceOrderId,
        marketplace: order.marketplace,
        status: order.status,
        orderDate: order.orderDate,
      },

      items: orderItems.map((item) => {
        const product = productMap.get(item.productId);

        const variant = item.variantId ? variantMap.get(item.variantId) : null;

        return {
          id: item.id,
          sku: variant?.sku ?? product?.sku ?? null,
          productName: product?.name ?? "Unknown Product",
          quantity: item.quantity,

          variant: variant
            ? {
                id: variant.id,
                sku: variant.sku,
                name: variant.name,
                color: variant.color,
                size: variant.size,
              }
            : null,

          product: product
            ? {
                id: product.id,
                sku: product.sku,
                name: product.name,
                imageUrl: product.imageUrl,
              }
            : null,
        };
      }),
    };
  }
}

export const scanService = new ScanService();
