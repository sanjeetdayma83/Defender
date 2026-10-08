import { Router } from "express";

import {
  listShipments,
  getShipment,
} from "../controllers/shipments/shipment.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.get(
  "/",
  loadAppUser,
  authorize("order.view"),
  listShipments,
);

router.get(
  "/:id",
  loadAppUser,
  authorize("order.view"),
  getShipment,
);

export default router;
