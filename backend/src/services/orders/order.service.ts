import { prisma } from "../../config/prisma.js";
import type { Order, OrderListFilters } from "../../models/order.model.js";

function mapOrder(record: any): Order {
  const shipment = record.shipments?.[0] ?? null;
  const item = record.items?.[0] ?? null;

  const product = item?.product ?? null;
  const variant = item?.variant ?? null;

  const media =
    shipment?.packingSessions?.flatMap((session: any) => session.media ?? []) ??
    [];

  return {
    id: record.id,

    awb: shipment?.awb ?? "",

    orderId: record.externalOrderId ?? record.marketplaceOrderId ?? "",

    marketplace: record.marketplace ?? "",

    sku: variant?.sku ?? product?.sku ?? "",

    quantity: item?.quantity ?? 0,

    status: record.status ?? "",

    evidenceExists: media.length > 0,

    product: {
      id: product?.id,

      sku: variant?.sku ?? product?.sku ?? "",

      name: product?.name ?? "Unknown Product",

      variant: variant?.variantName ?? variant?.name ?? "",

      color: variant?.color ?? "",

      image: variant?.imageUrl ?? product?.imageUrl ?? null,
    },

    shipmentId: shipment?.id,

    shipmentStatus: shipment?.status,

    carrier: shipment?.carrier ?? null,

    createdAt: record.createdAt?.toISOString?.() ?? undefined,

    updatedAt: record.updatedAt?.toISOString?.() ?? undefined,
  };
}

const includeGraph = {
  items: {
    include: {
      product: true,
      variant: true,
    },
  },

  shipments: {
    orderBy: {
      createdAt: "desc" as const,
    },

    take: 1,

    include: {
      barcodeAliases: true,

      packingSessions: {
        include: {
          media: true,
        },
      },
    },
  },
};

export class OrderService {
  async find(identifier: string): Promise<Order | null> {
    const value = identifier.trim();

    if (!value) {
      return null;
    }

    const order = await prisma.order.findFirst({
      where: {
        OR: [
          {
            externalOrderId: {
              equals: value,
              mode: "insensitive",
            },
          },

          {
            marketplaceOrderId: {
              equals: value,
              mode: "insensitive",
            },
          },

          {
            items: {
              some: {
                product: {
                  sku: {
                    equals: value,
                    mode: "insensitive",
                  },
                },
              },
            },
          },

          {
            items: {
              some: {
                variant: {
                  sku: {
                    equals: value,
                    mode: "insensitive",
                  },
                },
              },
            },
          },

          {
            shipments: {
              some: {
                awb: {
                  equals: value,
                  mode: "insensitive",
                },
              },
            },
          },

          {
            shipments: {
              some: {
                barcodeAliases: {
                  some: {
                    barcode: {
                      equals: value,
                      mode: "insensitive",
                    },
                    isActive: true,
                  },
                },
              },
            },
          },

          {
            items: {
              some: {
                product: {
                  barcodeAliases: {
                    some: {
                      barcode: {
                        equals: value,
                        mode: "insensitive",
                      },
                      isActive: true,
                    },
                  },
                },
              },
            },
          },
        ],
      },

      include: includeGraph,
    });

    if (!order) {
      return null;
    }

    return mapOrder(order);
  }

  async list(filters: OrderListFilters = {}): Promise<Order[]> {
    const search = filters.search?.trim();
    const status = filters.status?.trim();
    const marketplace = filters.marketplace?.trim();

    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (marketplace) {
      where.marketplace = marketplace;
    }

    if (search) {
      where.OR = [
        {
          externalOrderId: {
            contains: search,
            mode: "insensitive",
          },
        },

        {
          marketplaceOrderId: {
            contains: search,
            mode: "insensitive",
          },
        },

        {
          items: {
            some: {
              product: {
                sku: {
                  contains: search,
                  mode: "insensitive",
                },
              },
            },
          },
        },

        {
          items: {
            some: {
              variant: {
                sku: {
                  contains: search,
                  mode: "insensitive",
                },
              },
            },
          },
        },

        {
          shipments: {
            some: {
              awb: {
                contains: search,
                mode: "insensitive",
              },
            },
          },
        },

        {
          shipments: {
            some: {
              barcodeAliases: {
                some: {
                  barcode: {
                    contains: search,
                    mode: "insensitive",
                  },
                  isActive: true,
                },
              },
            },
          },
        },
      ];
    }

    const limit = Math.min(Math.max(Number(filters.limit ?? 100), 1), 500);

    const offset = Math.max(Number(filters.offset ?? 0), 0);

    const records = await prisma.order.findMany({
      where,

      orderBy: {
        createdAt: "desc",
      },

      skip: offset,

      take: limit,

      include: includeGraph,
    });

    return records.map(mapOrder);
  }
}
