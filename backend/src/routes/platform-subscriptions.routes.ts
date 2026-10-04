import { Router } from "express";
import { listPlatformSubscriptions } from "../controllers/platform/subscriptions.controller.js";

const router = Router();
router.get("/", listPlatformSubscriptions);
export default router;
