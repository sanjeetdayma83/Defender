import { Router } from "express";
import {
  createRazorpayOrder,
  verifyRazorpayPayment,
  getInvoicePdf,
} from "../controllers/billing/billing.controller.js";

const router = Router();

router.post("/razorpay/order", createRazorpayOrder);
router.post("/razorpay/verify", verifyRazorpayPayment);
router.get("/invoices/:invoiceId/pdf", getInvoicePdf);

export default router;

