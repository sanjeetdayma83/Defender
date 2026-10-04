import { Router } from "express";
import {
  listPlatformCompanies, setCompanyActive,
  listPlatformUsers, setUserStatus,
  listPlatformPlans, createPlatformPlan, updatePlatformPlan, setPlanActive,
  listPlatformSubscriptions,
  listTopups, createTopup, setTopupActive,
  storageOverview, analyticsSummary, listAuditLogs, getSettings, patchSettings,
} from "../controllers/platform/platform.controller.js";

export const platformCompaniesRouter = Router();
platformCompaniesRouter.get("/", listPlatformCompanies);
platformCompaniesRouter.patch("/:id/status", setCompanyActive);

export const platformUsersRouter = Router();
platformUsersRouter.get("/", listPlatformUsers);
platformUsersRouter.patch("/:id/status", setUserStatus);

export const platformPlansRouter = Router();
platformPlansRouter.get("/", listPlatformPlans);
platformPlansRouter.post("/", createPlatformPlan);
platformPlansRouter.patch("/:id", updatePlatformPlan);
platformPlansRouter.patch("/:id/status", setPlanActive);

export const platformSubscriptionsRouter = Router();
platformSubscriptionsRouter.get("/", listPlatformSubscriptions);

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
