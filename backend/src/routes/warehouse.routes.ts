import { Router } from "express";
import {
  createWarehouse,
  deleteWarehouse,
  getWarehouse,
  getWarehouseStats,
  listWarehouses,
  updateWarehouse,
  updateWarehouseStatus,
} from "../controllers/warehouse.controller.js";

const router = Router();

router.get("/", listWarehouses);
router.get("/:id", getWarehouse);
router.post("/", createWarehouse);
router.put("/:id", updateWarehouse);
router.patch("/:id/status", updateWarehouseStatus);
router.delete("/:id", deleteWarehouse);
router.get("/:id/stats", getWarehouseStats);

export default router;
