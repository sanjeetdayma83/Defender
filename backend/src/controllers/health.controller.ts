import type { Request, Response } from "express";

export function healthCheck(_req: Request, res: Response): void {
  res.status(200).json({
    success: true,
    service: "loss-defender-backend",
    status: "healthy",
    environment: process.env.NODE_ENV ?? "development",
    timestamp: new Date().toISOString(),
  });
}
