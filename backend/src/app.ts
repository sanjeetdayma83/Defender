import scanRouter from "./routes/scan.routes.js";
import importsRoutes from "./routes/imports.routes.js";
import productsRoutes from "./routes/products.routes.js";
import ordersRoutes from "./routes/orders.routes.js";
import shipmentsRoutes from "./routes/shipments.routes.js";
import plansRoutes from "./routes/plans.routes.js";
import walletRoutes from "./routes/wallet.routes.js";
import express from "express";
import onboardingRoutes from "./routes/onboarding.routes.js";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";

import storageRoutes from "./routes/storage.routes.js";
import { healthRouter } from "./routes/health.routes.js";
import authRoutes from "./routes/auth.routes.js";
import { firebaseAuthMiddleware } from "./middleware/firebase-auth.middleware.js";
import identityRoutes from "./routes/identity.routes.js";
import liveDashboardRoutes from "./routes/live-dashboard.routes.js";
import warehouseRoutes from "./routes/warehouse.routes.js";

import billingRoutes from "./routes/billing.routes.js";
import billingWebhookRoutes from "./routes/billing-webhook.routes.js";

dotenv.config();

export const app = express();

app.use(cors());
app.use(helmet());

app.use(
  express.json({
    limit: "10mb",
    verify: (req, _res, buffer) => {
      if ((req as express.Request).originalUrl === "/api/v1/billing/webhook/razorpay") {
        (req as express.Request & { rawBody?: Buffer }).rawBody =
          Buffer.from(buffer);
      }
    },
  }),
);

/*
 * Public health endpoint.
 */
app.use("/api/v1/plans", firebaseAuthMiddleware, plansRoutes);

app.use("/api/v1/wallet", firebaseAuthMiddleware, walletRoutes);
app.use("/api/v1/imports", firebaseAuthMiddleware, importsRoutes);

app.use("/api/v1/products", firebaseAuthMiddleware, productsRoutes);

app.use("/api/v1/orders", firebaseAuthMiddleware, ordersRoutes);

app.use("/api/v1/shipments", firebaseAuthMiddleware, shipmentsRoutes);
app.use("/api/v1/health", healthRouter);

/*
 * Firebase-authenticated endpoints.
 */
app.use("/api/v1/auth", firebaseAuthMiddleware, authRoutes);

app.use("/api/v1/storage", firebaseAuthMiddleware, storageRoutes);

/*
 * Razorpay webhook MUST be public.
 */
app.use("/api/v1/billing/webhook", billingWebhookRoutes);

/*
 * Customer billing APIs require Firebase authentication.
 */
app.use("/api/v1/billing", firebaseAuthMiddleware, billingRoutes);

app.get("/", (_req, res) => {
  res.json({
    success: true,
    service: "loss-defender-backend",
  });
});

app.use("/api/v1/onboarding", firebaseAuthMiddleware, onboardingRoutes);
app.use("/api/v1/identity", firebaseAuthMiddleware, identityRoutes);
app.use("/api/v1/dashboard", firebaseAuthMiddleware, liveDashboardRoutes);
app.use("/api/v1/warehouses", firebaseAuthMiddleware, warehouseRoutes);

app.use(
  (
    error: unknown,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    console.error(error);

    res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  },
);

app.use("/api/v1/scan", scanRouter);

