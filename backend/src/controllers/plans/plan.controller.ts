import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { planService } from "../../services/plans/plan.service.js";
import { companyContextService } from "../../services/identity/company-context.service.js";

export async function listPlans(
  _req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const plans = await planService.listActive();

  res.json({
    success: true,
    data: plans,
  });
}

export async function getSubscription(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const firebaseUid = req.firebaseUser?.uid;

  if (!firebaseUid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  const { company } = await companyContextService.getCompany(firebaseUid);

  const subscription = await planService.getSubscription(company.id);

  res.json({
    success: true,
    data: subscription,
  });
}

export async function subscribe(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const firebaseUid = req.firebaseUser?.uid;

  if (!firebaseUid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  const { user, company } = await companyContextService.getCompany(firebaseUid);

  if (!["OWNER", "ADMIN"].includes(user.role)) {
    res.status(403).json({
      success: false,
      message: "Only company owners or admins can change subscription.",
    });
    return;
  }

  const planId = String(req.body?.planId ?? "").trim();

  if (!planId) {
    res.status(400).json({
      success: false,
      message: "planId is required.",
    });
    return;
  }

  const billingInterval =
    req.body?.billingInterval === "YEARLY" ? "YEARLY" : "MONTHLY";

  const subscription = await planService.subscribeCompany({
    companyId: company.id,
    planId,
    billingInterval,
  });

  res.json({
    success: true,
    data: subscription,
  });
}
