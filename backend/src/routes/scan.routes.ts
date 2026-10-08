import { Router } from "express";

import { lookupScan } from "../controllers/scan/scan.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.post(
  "/lookup",
  loadAppUser,
  authorize("scan.lookup"),
  lookupScan,
);

export default router;
