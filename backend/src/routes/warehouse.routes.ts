import { Router } from "express";
import { listWarehouses } from "../controllers/warehouse.controller.js";

const router = Router();

router.get("/", listWarehouses);

export default router;
