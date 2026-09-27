import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { onboardingService } from "../../services/onboarding/onboarding.service.js";

function firebaseUid(req: AuthenticatedRequest): string {
  const uid = req.firebaseUser?.uid;

  if (!uid) {
    throw new Error("AUTH_REQUIRED");
  }

  return uid;
}

function messageFor(error: unknown): string {
  if (!(error instanceof Error)) {
    return "Request failed.";
  }

  const messages: Record<string, string> = {
    AUTH_REQUIRED: "Authentication required.",
    USER_NOT_FOUND: "User profile not found.",
    NAME_REQUIRED: "Name is required.",
    COMPANY_NAME_REQUIRED: "Company name is required.",
    COMPANY_CODE_EXISTS: "Company code already exists.",
    COMPANY_NOT_FOUND: "Company not found.",
    WAREHOUSE_NAME_REQUIRED: "Warehouse name is required.",
    WAREHOUSE_CODE_EXISTS: "Warehouse code already exists.",
    WAREHOUSE_REQUIRED: "At least one warehouse is required.",
  };

  return messages[error.message] ?? error.message;
}

function statusFor(error: unknown): number {
  if (!(error instanceof Error)) {
    return 500;
  }

  const badRequest = [
    "NAME_REQUIRED",
    "COMPANY_NAME_REQUIRED",
    "COMPANY_CODE_EXISTS",
    "WAREHOUSE_NAME_REQUIRED",
    "WAREHOUSE_CODE_EXISTS",
    "WAREHOUSE_REQUIRED",
  ];

  if (badRequest.includes(error.message)) {
    return 400;
  }

  if (
    error.message === "USER_NOT_FOUND" ||
    error.message === "COMPANY_NOT_FOUND"
  ) {
    return 404;
  }

  if (error.message === "AUTH_REQUIRED") {
    return 401;
  }

  return 500;
}

export async function getOnboardingStatus(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const result = await onboardingService.getStatus(firebaseUid(req));

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("[Onboarding] status failed:", error);

    res.status(statusFor(error)).json({
      success: false,
      message: messageFor(error),
    });
  }
}

export async function updateProfile(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const result = await onboardingService.updateProfile(firebaseUid(req), {
      name: req.body?.name,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("[Onboarding] profile update failed:", error);

    res.status(statusFor(error)).json({
      success: false,
      message: messageFor(error),
    });
  }
}

export async function updateCompany(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const result = await onboardingService.updateCompany(firebaseUid(req), {
      name: req.body?.name,
      code: req.body?.code,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("[Onboarding] company update failed:", error);

    res.status(statusFor(error)).json({
      success: false,
      message: messageFor(error),
    });
  }
}

export async function createWarehouse(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const result = await onboardingService.createWarehouse(firebaseUid(req), {
      name: req.body?.name,
      code: req.body?.code,
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("[Onboarding] warehouse creation failed:", error);

    res.status(statusFor(error)).json({
      success: false,
      message: messageFor(error),
    });
  }
}

export async function completeOnboarding(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const result = await onboardingService.complete(firebaseUid(req));

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("[Onboarding] completion failed:", error);

    res.status(statusFor(error)).json({
      success: false,
      message: messageFor(error),
    });
  }
}
