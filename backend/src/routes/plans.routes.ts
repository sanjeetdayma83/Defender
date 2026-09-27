import { Router } from "express";
import {
  listPlans,
  getSubscription,
  subscribe,
} from "../controllers/plans/plan.controller.js";

const router = Router();

router.get("/", listPlans);
router.get("/subscription", getSubscription);
router.post("/subscription", subscribe);

export default router;
