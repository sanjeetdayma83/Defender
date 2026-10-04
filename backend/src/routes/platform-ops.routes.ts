import { Router } from "express";
import {
  listTopups, createTopup, setTopupActive,
  storageOverview, analyticsSummary, listAuditLogs,
  getSettings, patchSettings,
} from "../controllers/platform/ops.controller.js";

export const platformTopupsRouter = Router();
platformTopupsRouter.get("/", listTopups);
platformTopupsRouter.post("/", createTopup);
platformTopupsRouter.patch("/:id/status", setTopupActive);

export const platformStorageRouter = Router();
platformStorageRouter.get("/", storageOverview);

export const platformAnalyticsRouter = Router();
platformAnalyticsRouter.get("/summary", analyticsSummary);

export const platformAuditRouter = Router();
platformAuditRouter.get("/", listAuditLogs);

export const platformSettingsRouter = Router();
platformSettingsRouter.get("/", getSettings);
platformSettingsRouter.patch("/", patchSettings);
