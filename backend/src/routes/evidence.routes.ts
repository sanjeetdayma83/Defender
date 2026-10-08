import { Router } from "express";
import {
  createEvidence,
  listEvidence,
} from "../controllers/evidence.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.post(
  "/",
  loadAppUser,
  authorize("recording.upload"),
  createEvidence,
);

router.get(
  "/:awb",
  loadAppUser,
  authorize("evidence.view"),
  listEvidence,
);

export default router;
