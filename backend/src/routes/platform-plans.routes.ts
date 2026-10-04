import { Router } from "express";
import {
  listPlatformPlans,
  createPlatformPlan,
  updatePlatformPlan,
  setPlanActive,
} from "../controllers/platform/plans.controller.js";

const router = Router();

router.get("/", listPlatformPlans);
router.post("/", createPlatformPlan);
router.patch("/:id", updatePlatformPlan);
router.patch("/:id/status", setPlanActive);

export default router;
