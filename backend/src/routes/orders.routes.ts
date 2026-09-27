import { Router } from "express";

import {
  listOrders,
  getOrder,
  lookupOrder,
} from "../controllers/orders/order.controller.js";

const router = Router();

router.get("/", listOrders);
router.get("/lookup", lookupOrder);
router.get("/:id", getOrder);

export default router;
