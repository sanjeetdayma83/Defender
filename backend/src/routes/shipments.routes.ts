import { Router } from "express";

import {
  listShipments,
  getShipment,
} from "../controllers/shipments/shipment.controller.js";

const router = Router();

router.get("/", listShipments);
router.get("/:id", getShipment);

export default router;
