import { Router } from "express";

import {
  getCompanyDashboard,
  getPlatformDashboard,
} from "../controllers/identity/dashboard.controller.js";

const router = Router();

router.get("/", getCompanyDashboard);
router.get("/platform", getPlatformDashboard);

export default router;
