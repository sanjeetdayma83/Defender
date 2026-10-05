import { Router } from "express";
import {
  getPlatformCompany,
  listPlatformCompanies,
  setCompanyActive,
} from "../controllers/platform/companies.controller.js";

const router = Router();

router.get("/", listPlatformCompanies);
router.get("/:id", getPlatformCompany);
router.patch("/:id/status", setCompanyActive);

export default router;