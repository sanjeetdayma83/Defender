import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { requirePlatformAdmin } from "../../services/platform/platform-admin.guard.js";
import { PlatformTopupsService } from "../../services/platform/platform-topups.service.js";
import { PlatformOpsService } from "../../services/platform/platform-ops.service.js";

const topups = new PlatformTopupsService();
const ops = new PlatformOpsService();

export async function listTopups(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await topups.list();
    res.json({ success: true, data });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, message: "Unable to load top-ups." });
  }
}

export async function createTopup(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await topups.create(req.body ?? {});
    res.status(201).json({ success: true, data });
  } catch (e: any) {
    res.status(400).json({ success: false, message: e?.message ?? "Create failed." });
  }
}

export async function setTopupActive(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    const data = await topups.setActive(req.params.id, Boolean(req.body?.isActive));
    res.json({ success: true, data });
  } catch (e) {
    res.status(500).json({ success: false, message: "Update failed." });
  }
}

export async function storageOverview(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.storageOverview() });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to load storage." });
  }
}

export async function analyticsSummary(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.analyticsSummary() });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to load analytics." });
  }
}

export async function listAuditLogs(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.auditLogs(Number(req.query.limit ?? 100)) });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to load audit logs." });
  }
}

export async function getSettings(req: AuthenticatedRequest, res: Response) {
  try {
    if (!(await requirePlatformAdmin(req, res))) return;
    res.json({ success: true, data: await ops.getSettings() });
  } catch (e) {
    res.status(500).json({ success: false, message: "Unable to load settings." });
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
