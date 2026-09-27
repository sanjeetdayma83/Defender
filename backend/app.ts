import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import storageRoutes from "./routes/storage.routes.js";
import { healthRouter } from "./routes/health.routes.js";
import { orderRouter } from "./routes/order.routes.js";
import { clerkMiddleware } from "@clerk/express";
import authRoutes from "./routes/auth.routes.js";

dotenv.config();

export const app = express();

app.use(clerkMiddleware());

/*
 * Middleware must be registered BEFORE API routes.
 *
 * Flutter Web runs on a dynamic localhost port, for example:
 * http://localhost:61264
 *
 * cors() allows the development frontend to communicate with
 * this backend and ensures Access-Control-Allow-Origin is added
 * to the API responses.
 */
app.use(cors());

app.use(helmet());

app.use(express.json({ limit: "10mb" }));

/*
 * API Routes
 */

app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/storage", storageRoutes);
app.use("/api/v1/health", healthRouter);
app.use("/api/v1/orders", orderRouter);

app.get("/", (_req, res) => {
  res.json({
    success: true,
    service: "loss-defender-backend",
  });
});

/*
 * Global error handler
 */
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
