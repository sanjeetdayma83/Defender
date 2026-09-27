import { Router } from "express";
import { findOrder, listOrders } from "../controllers/order.controller.js";

export const orderRouter = Router();

orderRouter.get("/", listOrders);
orderRouter.get("/:identifier", findOrder);
