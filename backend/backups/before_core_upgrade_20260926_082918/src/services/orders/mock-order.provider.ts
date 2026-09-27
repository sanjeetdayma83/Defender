import type { Order } from "../../models/order.model.js";

const orders: Order[] = [
  {
    awb: "368275770371",
    orderId: "406-3151945-3281902",
    marketplace: "Amazon",
    sku: "97-U1YR-N3GW",
    quantity: 1,
    status: "Pending Packing",
    evidenceExists: false,
  },
  {
    awb: "1490841263428112",
    orderId: "331724360573683072_1",
    marketplace: "Delhivery",
    sku: "PC-TWISTER-001",
    quantity: 1,
    status: "Pending Packing",
    evidenceExists: false,
  },
  {
    awb: "FMPP3767030215",
    orderId: "FK-3767030215",
    marketplace: "Flipkart",
    sku: "DG-LT-S",
    quantity: 1,
    status: "Verified",
    evidenceExists: true,
  },
];

export class MockOrderProvider {
  async findByIdentifier(identifier: string): Promise<Order | null> {
    const value = identifier.trim().toUpperCase();

    return (
      orders.find(
        (order) =>
          order.awb.toUpperCase() === value ||
          order.orderId.toUpperCase() === value ||
          order.sku.toUpperCase() === value,
      ) ?? null
    );
  }

  async list(): Promise<Order[]> {
    return orders;
  }
}
