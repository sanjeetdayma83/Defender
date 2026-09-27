import { Router } from "express";
import { getDashboardMetrics } from "../controllers/dashboard.controller.js";

const router = Router();

router.get("/metrics", getDashboardMetrics);

export default router;
