import type { Order } from "../../models/order.model.js";

const mockOrders: Order[] = [
  {
    awb: "368275770371",
    orderId: "406-3151945-3281902",
    marketplace: "Amazon",
    sku: "97-U1YR-N3GW",
    quantity: 1,
    status: "Pending Packing",
    evidenceExists: false,

    product: {
      sku: "97-U1YR-N3GW",
      name: "Demo Product",
      variant: "",
      color: "",
    },
  },

  {
    awb: "1490841263428112",
    orderId: "331724360573683072_1",
    marketplace: "Delhivery",
    sku: "PC-TWISTER-001",
    quantity: 1,
    status: "Pending Packing",
    evidenceExists: false,

    product: {
      sku: "PC-TWISTER-001",
      name: "PC Twister Demo",
      variant: "",
      color: "Blue",
    },
  },

  {
    awb: "FMPP3767030215",
    orderId: "FK-3767030215",
    marketplace: "Flipkart",
    sku: "DG-LT-S",
    quantity: 1,
    status: "Verified",
    evidenceExists: true,

    product: {
      sku: "DG-LT-S",
      name: "NOVELTY Foldable Height Adjustable White Board",
      variant: "",
      color: "",
    },
  },
];

export class MockOrderProvider {
  async findByIdentifier(identifier: string): Promise<Order | null> {
    const value = identifier.trim().toLowerCase();

    return (
      mockOrders.find(
        (order) =>
          order.awb.toLowerCase() === value ||
          order.orderId.toLowerCase() === value ||
          order.sku.toLowerCase() === value ||
          order.product.sku.toLowerCase() === value,
      ) ?? null
    );
  }

  async list(): Promise<Order[]> {
    return [...mockOrders];
  }
}
