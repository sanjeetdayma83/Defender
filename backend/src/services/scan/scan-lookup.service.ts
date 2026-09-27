import { prisma } from "../../config/prisma.js";

export interface ScanLookupResult {
  found: boolean;
  lookupType:
    | "AWB"
    | "SHIPMENT_BARCODE"
    | "ORDER_ID"
    | "MARKETPLACE_ORDER_ID"
    | "SKU"
    | "NONE";
  ambiguous?: boolean;
  message: string;
  shipment?: unknown;
  order?: unknown;
  products?: unknown[];
}

export class ScanLookupService {
  async lookup(companyId: string, value: string): Promise<ScanLookupResult> {
    const barcode = value.trim();

    if (!barcode) {
      return {
        found: false,
        lookupType: "NONE",
        message: "Barcode is empty.",
      };
    }

    const shipment = await prisma.shipment.findFirst({
      where: {
        awb: barcode,
        order: {
          companyId,
        },
      },
      include: {
        barcodeAliases: true,
        order: {
          include: {
            warehouse: true,
            items: {
              include: {
                product: {
                  include: {
                    variants: true,
                  },
                },
                variant: true,
              },
            },
          },
        },
      },
    });

    if (shipment) {
      return {
        found: true,
        lookupType: "AWB",
        message: "Shipment found.",
        shipment,
        order: shipment.order,
      };
    }

    const shipmentBarcode = await prisma.shipmentBarcode.findFirst({
      where: {
        barcode,
        isActive: true,
        shipment: {
          order: {
            companyId,
          },
        },
      },
      include: {
        shipment: {
          include: {
            barcodeAliases: true,
            order: {
              include: {
                warehouse: true,
                items: {
                  include: {
                    product: {
                      include: {
                        variants: true,
                      },
                    },
                    variant: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (shipmentBarcode) {
      return {
        found: true,
        lookupType: "SHIPMENT_BARCODE",
        message: "Shipment barcode found.",
        shipment: shipmentBarcode.shipment,
        order: shipmentBarcode.shipment.order,
      };
    }

    const order = await prisma.order.findFirst({
      where: {
        companyId,
        OR: [
          {
            externalOrderId: barcode,
          },
          {
            marketplaceOrderId: barcode,
          },
        ],
      },
      include: {
        warehouse: true,
        shipments: {
          include: {
            barcodeAliases: true,
          },
        },
        items: {
          include: {
            product: {
              include: {
                variants: true,
              },
            },
            variant: true,
          },
        },
      },
    });

    if (order) {
      const shipment =
        order.shipments.find(
          (item) =>
            item.status === "READY_TO_PACK" || item.status === "CREATED",
        ) ?? order.shipments[0];

      return {
        found: true,
        lookupType:
          order.externalOrderId === barcode
            ? "ORDER_ID"
            : "MARKETPLACE_ORDER_ID",
        message: "Order found.",
        shipment,
        order,
      };
    }

    const products = await prisma.product.findMany({
      where: {
        companyId,
        isActive: true,
        sku: barcode,
      },
      include: {
        variants: true,
      },
    });

    if (products.length > 0) {
      const orders = await prisma.order.findMany({
        where: {
          companyId,
          status: {
            in: ["PENDING", "CONFIRMED"],
          },
          items: {
            some: {
              productId: {
                in: products.map((product) => product.id),
              },
            },
          },
        },
        include: {
          warehouse: true,
          shipments: true,
          items: {
            include: {
              product: true,
              variant: true,
            },
          },
        },
      });

      if (orders.length === 1) {
        return {
          found: true,
          lookupType: "SKU",
          message: "SKU matched one pending order.",
          shipment: orders[0].shipments[0],
          order: orders[0],
          products,
        };
      }

      if (orders.length > 1) {
        return {
          found: false,
          lookupType: "SKU",
          ambiguous: true,
          message:
            "SKU exists on multiple pending orders. Scan the shipping barcode/AWB instead.",
          products,
        };
      }

      return {
        found: false,
        lookupType: "SKU",
        message: "SKU exists, but no pending order is currently available.",
        products,
      };
    }

    return {
      found: false,
      lookupType: "NONE",
      message: "No shipment, order or SKU matched this barcode.",
    };
  }
}

export const scanLookupService = new ScanLookupService();
