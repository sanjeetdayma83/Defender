import { Router } from "express";
import {
  getWallet,
  getWalletTransactions,
} from "../controllers/wallet/wallet.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.get(
  "/",
  loadAppUser,
  authorize("wallet.view_balance"),
  getWallet,
);

router.get(
  "/transactions",
  loadAppUser,
  authorize("wallet.view_history"),
  getWalletTransactions,
);

export default router;
