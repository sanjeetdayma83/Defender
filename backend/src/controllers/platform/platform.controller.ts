import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { requirePlatformAdmin } from "../../services/platform/platform-admin.guard.js";
import { PlatformCompaniesService } from "../../services/platform/platform-companies.service.js";
import { PlatformUsersService } from "../../services/platform/platform-users.service.js";
import { PlatformPlansService } from "../../services/platform/platform-plans.service.js";
import { PlatformSubscriptionsService } from "../../services/platform/platform-subscriptions.service.js";
import { PlatformTopupsService } from "../../services/platform/platform-topups.service.js";
import { PlatformOpsService } from "../../services/platform/platform-ops.service.js";

const companies = new PlatformCompaniesService();
const users = new PlatformUsersService();
const plans = new PlatformPlansService();
const subscriptions = new PlatformSubscriptionsService();
const topups = new PlatformTopupsService();
const ops = new PlatformOpsService();

export async function listPlatformCompanies(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const search = typeof req.query.search === "string" ? req.query.search : "";
    const statusRaw = typeof req.query.status === "string" ? req.query.status : "all";
    const status = statusRaw === "active" || statusRaw === "inactive" ? statusRaw : "all";
    const data = await companies.list({ search, status, limit: Number(req.query.limit ?? 50) });
    res.json({ success: true, data });
  } catch (e) {
    console.error("listPlatformCompanies", e);
    res.json({ success: true, data: { total: 0, items: [] } });
  }
}
export async function setCompanyActive(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await companies.setActive(req.params.id, Boolean(req.body?.isActive));
    res.json({ success: true, data });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, message: "Unable to update company." });
  }
}

export async function listPlatformUsers(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await users.list({
      search: typeof req.query.search === "string" ? req.query.search : "",
      status: (["active","inactive"].includes(String(req.query.status)) ? req.query.status : "all") as any,
      role: typeof req.query.role === "string" ? req.query.role : "",
      limit: Number(req.query.limit ?? 100),
    });
    res.json({ success: true, data });
  } catch (e) {
    console.error(e);
    res.json({ success: true, data: { total: 0, items: [] } });
  }
}
export async function setUserStatus(req: AuthenticatedRequest, res: Response) {
  try {
    const admin = await requirePlatformAdmin(req, res);
    if (!admin) return;
    if (admin.id === req.params.id && !req.body?.isActive) {
      res.status(400).json({ success: false, message: "Cannot suspend your own account." });
      return;
    }
    const data = await users.setStatus(req.params.id, Boolean(req.body?.isActive));
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to update user." });
  }
}

export async function listPlatformPlans(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await plans.list({ activeOnly: req.query.active === "true", limit: Number(req.query.limit ?? 100) });
    res.json({ success: true, data });
  } catch (e) {
    console.error(e);
    res.json({ success: true, data: { total: 0, items: [] } });
  }
}
export async function createPlatformPlan(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await plans.create(req.body ?? {});
    res.status(201).json({ success: true, data });
  } catch (e: any) {
    res.status(400).json({ success: false, message: e?.message ?? "Create failed" });
  }
}
export async function updatePlatformPlan(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await plans.update(req.params.id, req.body ?? {});
    res.json({ success: true, data });
  } catch (e: any) {
    res.status(e?.message === "PLAN_NOT_FOUND" ? 404 : 400).json({ success: false, message: e?.message ?? "Update failed" });
  }
}
export async function setPlanActive(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await plans.setActive(req.params.id, Boolean(req.body?.isActive));
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to update plan." });
  }
}

export async function listPlatformSubscriptions(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await subscriptions.list({
      search: typeof req.query.search === "string" ? req.query.search : "",
      status: typeof req.query.status === "string" ? req.query.status : "all",
      limit: Number(req.query.limit ?? 100),
    });
    res.json({ success: true, data });
  } catch (e) {
    console.error(e);
    res.json({ success: true, data: { total: 0, items: [] } });
  }
}

export async function listTopups(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await topups.list() });
  } catch (e) {
    res.json({ success: true, data: { total: 0, items: [] } });
  }
}
export async function createTopup(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.status(201).json({ success: true, data: await topups.create(req.body ?? {}) });
  } catch (e: any) {
    res.status(400).json({ success: false, message: e?.message ?? "Create failed" });
  }
}
export async function setTopupActive(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await topups.setActive(req.params.id, Boolean(req.body?.isActive)) });
  } catch (e) {
    res.status(500).json({ success: false, message: "Update failed" });
  }
}

export async function storageOverview(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.storageOverview() });
  } catch (e) {
    res.json({ success: true, data: { totalBytes: 0, items: [] } });
  }
}
export async function analyticsSummary(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.analyticsSummary() });
  } catch (e) {
    res.json({ success: true, data: { companies: 0, users: 0, activeSubscriptions: 0 } });
  }
}
export async function listAuditLogs(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.auditLogs(Number(req.query.limit ?? 100)) });
  } catch (e) {
    res.json({ success: true, data: { total: 0, items: [] } });
  }
}
export async function getSettings(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.getSettings() });
  } catch (e) {
    res.json({ success: true, data: { maintenanceMode: "false", allowNewSignups: "true" } });
  }
}
export async function patchSettings(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.patchSettings(req.body ?? {}) });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to save settings." });
  }
}
