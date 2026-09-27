import { Router } from "express";
import {
  createEvidence,
  listEvidence,
} from "../controllers/evidence.controller.js";

const router = Router();

router.post("/", createEvidence);
router.get("/:awb", listEvidence);

export default router;
