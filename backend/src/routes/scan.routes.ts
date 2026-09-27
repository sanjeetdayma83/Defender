import { Router } from "express";
import { firebaseAuthMiddleware } from "../middleware/firebase-auth.middleware.js";
import { lookupScan } from "../controllers/scan/scan.controller.js";

const router = Router();

router.use(firebaseAuthMiddleware);

router.post("/lookup", lookupScan);

export default router;
