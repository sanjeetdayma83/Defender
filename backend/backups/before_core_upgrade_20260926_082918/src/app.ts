import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";

import storageRoutes from "./routes/storage.routes.js";
import { healthRouter } from "./routes/health.routes.js";
import { orderRouter } from "./routes/order.routes.js";
import authRoutes from "./routes/auth.routes.js";
import { firebaseAuthMiddleware } from "./middleware/firebase-auth.middleware.js";

dotenv.config();

export const app = express();

app.use(cors());
app.use(helmet());
app.use(express.json({ limit: "10mb" }));

/*
 * Public health endpoint.
 */
app.use("/api/v1/health", healthRouter);

/*
 * Firebase-authenticated endpoints.
 */
app.use(
  "/api/v1/auth",
  firebaseAuthMiddleware,
  authRoutes,
);

app.use(
  "/api/v1/storage",
  firebaseAuthMiddleware,
  storageRoutes,
);

app.use(
  "/api/v1/orders",
  firebaseAuthMiddleware,
  orderRouter,
);

app.get("/", (_req, res) => {
  res.json({
    success: true,
    service: "loss-defender-backend",
  });
});

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
