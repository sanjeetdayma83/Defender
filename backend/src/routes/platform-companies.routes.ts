import { Router } from "express";
import {
  listPlatformCompanies,
  setCompanyActive,
} from "../controllers/platform/companies.controller.js";

const router = Router();

router.get("/", listPlatformCompanies);
router.patch("/:id/status", setCompanyActive);

export default router;
