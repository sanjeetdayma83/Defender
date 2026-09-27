import { Router } from "express";
import {
  cancelPacking,
  completePacking,
  getPacking,
  getPackingByShipment,
  startPacking,
} from "../controllers/packing.controller.js";

const router = Router();

router.post("/", startPacking);
router.get("/shipment/:shipmentId", getPackingByShipment);
router.get("/:id", getPacking);
router.post("/:id/complete", completePacking);
router.post("/:id/cancel", cancelPacking);

export default router;
