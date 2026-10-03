import { Router } from "express";
import {
  getWallet,
  consumeCredits,
  topUpCredits,
  refundCredits,
} from "../controllers/wallet/wallet.controller.js";

const router = Router();

router.get("/", getWallet);
router.post("/consume", consumeCredits);
router.post("/top-up", topUpCredits);
router.post("/refund", refundCredits);

export default router;
