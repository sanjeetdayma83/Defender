import type { Request, Response } from "express";
import { OrderService } from "../services/orders/order.service.js";

const service = new OrderService();

export async function findOrder(req: Request, res: Response) {
  const identifier = String(req.params.identifier ?? "").trim();

  if (!identifier) {
    return res.status(400).json({
      success: false,
      message: "Identifier is required",
    });
  }

  const order = await service.find(identifier);

  if (!order) {
    return res.status(404).json({
      success: false,
      message: "Shipment not found",
    });
  }

  return res.json({
    success: true,
    data: order,
  });
}

export async function listOrders(_req: Request, res: Response) {
  return res.json({
    success: true,
    data: await service.list(),
  });
}
