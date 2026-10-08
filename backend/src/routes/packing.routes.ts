import { Router } from "express";
import {
  cancelPacking,
  completePacking,
  getPacking,
  getPackingByShipment,
  startPacking,
} from "../controllers/packing.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.post(
  "/",
  loadAppUser,
  authorize("packing.start"),
  startPacking,
);

router.get(
  "/shipment/:shipmentId",
  loadAppUser,
  authorize("order.view"),
  getPackingByShipment,
);

router.get(
  "/:id",
  loadAppUser,
  authorize("order.view"),
  getPacking,
);

router.post(
  "/:id/complete",
  loadAppUser,
  authorize("packing.complete"),
  completePacking,
);

router.post(
  "/:id/cancel",
  loadAppUser,
  authorize("packing.cancel"),
  cancelPacking,
);

export default router;
