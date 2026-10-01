import { Router } from "express";
import { razorpayWebhook } from "../controllers/billing/razorpay-webhook.controller.js";

const router = Router();

router.post("/razorpay", razorpayWebhook);

export default router;
