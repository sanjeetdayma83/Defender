import type { Request, Response } from "express";
import { OrderService } from "../services/orders/order.service.js";

const service = new OrderService();

export async function findOrder(req: Request, res: Response) {
  try {
    const identifier = String(req.params.identifier ?? "").trim();

    if (!identifier) {
      return res.status(400).json({
        success: false,
        message: "Identifier is required.",
      });
    }

    const order = await service.find(identifier);

    if (!order) {
      return res.status(404).json({
        success: false,
        code: "ORDER_NOT_FOUND",
        message: "Shipment or order not found.",
      });
    }

    return res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error("Order lookup failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to resolve order.",
    });
  }
}

export async function listOrders(req: Request, res: Response) {
  try {
    const orders = await service.list({
      search:
        typeof req.query.search === "string" ? req.query.search : undefined,
      status:
        typeof req.query.status === "string" ? req.query.status : undefined,
      marketplace:
        typeof req.query.marketplace === "string"
          ? req.query.marketplace
          : undefined,
      limit:
        typeof req.query.limit === "string"
          ? Number(req.query.limit)
          : undefined,
      offset:
        typeof req.query.offset === "string"
          ? Number(req.query.offset)
          : undefined,
    });

    return res.json({
      success: true,
      data: orders,
      count: orders.length,
    });
  } catch (error) {
    console.error("Order listing failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to load orders.",
    });
  }
}
