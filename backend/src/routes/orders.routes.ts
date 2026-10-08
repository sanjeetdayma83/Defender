import { Router } from "express";

import {
  listOrders,
  getOrder,
  lookupOrder,
} from "../controllers/orders/order.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.get(
  "/",
  loadAppUser,
  authorize("order.view"),
  listOrders,
);

router.get(
  "/lookup",
  loadAppUser,
  authorize("order.view"),
  lookupOrder,
);

router.get(
  "/:id",
  loadAppUser,
  authorize("order.view"),
  getOrder,
);

export default router;
