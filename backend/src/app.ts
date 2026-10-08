import { platformCompaniesRouter, platformUsersRouter, platformPlansRouter, platformSubscriptionsRouter, platformTopupsRouter, platformStorageRouter, platformAnalyticsRouter, platformAuditRouter, platformSettingsRouter } from "./routes/platform-all.routes.js";
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
import packingRoutes from "./routes/packing.routes.js";
import evidenceRoutes from "./routes/evidence.routes.js";
import { healthRouter } from "./routes/health.routes.js";
import authRoutes from "./routes/auth.routes.js";
import { firebaseAuthMiddleware } from "./middleware/firebase-auth.middleware.js";
import identityRoutes from "./routes/identity.routes.js";
import invitationRoutes from "./routes/invitation.routes.js";
import liveDashboardRoutes from "./routes/live-dashboard.routes.js";
import warehouseRoutes from "./routes/warehouse.routes.js";

import billingRoutes from "./routes/billing.routes.js";
import billingWebhookRoutes from "./routes/billing-webhook.routes.js";

dotenv.config();

export const app = express();
//
// LOSS_DEFENDER_API_CACHE_POLICY_V1
// API responses are dynamic, authenticated and tenant-scoped.
// Do not let the browser/proxies reuse stale API representations.
//
app.disable("etag");

app.use("/api/v1", (_req, res, next) => {
  res.setHeader(
    "Cache-Control",
    "no-store, no-cache, must-revalidate, proxy-revalidate",
  );
  res.setHeader("Pragma", "no-cache");
  res.setHeader("Expires", "0");
  next();
});

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
app.use("/api/v1/packing", firebaseAuthMiddleware, packingRoutes);
app.use("/api/v1/evidence", firebaseAuthMiddleware, evidenceRoutes);

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
app.use("/api/v1/invitations", invitationRoutes);
app.use("/api/v1/identity", firebaseAuthMiddleware, identityRoutes);
app.use("/api/v1/dashboard", firebaseAuthMiddleware, liveDashboardRoutes);
app.use("/api/v1/platform/topups", firebaseAuthMiddleware, platformTopupsRouter);
app.use("/api/v1/platform/storage", firebaseAuthMiddleware, platformStorageRouter);
app.use("/api/v1/platform/analytics", firebaseAuthMiddleware, platformAnalyticsRouter);
app.use("/api/v1/platform/audit-logs", firebaseAuthMiddleware, platformAuditRouter);
app.use("/api/v1/platform/settings", firebaseAuthMiddleware, platformSettingsRouter);
app.use("/api/v1/warehouses", firebaseAuthMiddleware, warehouseRoutes);
app.use("/api/v1/platform/companies", firebaseAuthMiddleware, platformCompaniesRouter);
app.use("/api/v1/platform/users", firebaseAuthMiddleware, platformUsersRouter);
app.use("/api/v1/platform/plans", firebaseAuthMiddleware, platformPlansRouter);
app.use("/api/v1/platform/subscriptions", firebaseAuthMiddleware, platformSubscriptionsRouter);

app.use("/api/v1/scan", firebaseAuthMiddleware, scanRouter);

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
