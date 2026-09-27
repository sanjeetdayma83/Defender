import { Router } from "express";

import {
  completeOnboarding,
  createWarehouse,
  getOnboardingStatus,
  updateCompany,
  updateProfile,
} from "../controllers/onboarding/onboarding.controller.js";

const router = Router();

router.get("/", getOnboardingStatus);
router.put("/profile", updateProfile);
router.put("/company", updateCompany);
router.post("/warehouse", createWarehouse);
router.post("/complete", completeOnboarding);

export default router;
