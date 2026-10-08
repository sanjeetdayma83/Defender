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
    NAME_REQUIRED: "Your name is required.",
    EMAIL_REQUIRED: "Your email is required.",
    PHONE_REQUIRED: "Mobile number is required.",
    COMPANY_NAME_REQUIRED: "Company name is required.",
    ADDRESS_REQUIRED: "Company address is required.",
    CITY_REQUIRED: "City is required.",
    STATE_REQUIRED: "State is required.",
    PIN_REQUIRED: "PIN code is required.",
    WAREHOUSE_NAME_REQUIRED: "Warehouse name is required.",
    WAREHOUSE_CODE_EXISTS: "Warehouse code already exists.",
    ACCOUNT_ALREADY_PROVISIONED:
      "This email is already associated with a Loss Defender account. Please sign in with that account.",
  };

  return messages[error.message] ?? error.message;
}

function statusFor(error: unknown): number {
  if (!(error instanceof Error)) {
    return 500;
  }

  if (error.message === "AUTH_REQUIRED") {
    return 401;
  }

  if (error.message === "USER_NOT_FOUND") {
    return 404;
  }

  if (error.message === "ACCOUNT_ALREADY_PROVISIONED") {
    return 409;
  }

  return 400;
}

export async function getOnboardingStatus(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    res.json({
      success: true,
      data: await onboardingService.getStatus(firebaseUid(req)),
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
    res.json({
      success: true,
      data: await onboardingService.updateProfile(firebaseUid(req), {
        name: req.body?.name,
      }),
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
    res.json({
      success: true,
      data: await onboardingService.updateCompany(firebaseUid(req), {
        name: req.body?.name,
        phone: req.body?.phone,
        address: req.body?.address,
        city: req.body?.city,
        state: req.body?.state,
        pin: req.body?.pin,
      }),
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
    res.status(201).json({
      success: true,
      data: await onboardingService.createWarehouse(firebaseUid(req), {
        name: req.body?.name,
        code: req.body?.code,
        address: req.body?.address,
        city: req.body?.city,
        state: req.body?.state,
      }),
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
    res.status(201).json({
      success: true,
      data: await onboardingService.complete(firebaseUid(req), {
        name: req.body?.name,
        email: req.firebaseUser?.email,
        phone: req.body?.phone,
        companyName: req.body?.companyName,
        address: req.body?.address,
        city: req.body?.city,
        state: req.body?.state,
        pin: req.body?.pin,
        warehouseName: req.body?.warehouseName,
        warehouseCode: req.body?.warehouseCode,
      }),
    });
  } catch (error) {
    console.error("[Onboarding] completion failed:", error);
    res.status(statusFor(error)).json({
      success: false,
      message: messageFor(error),
    });
  }
}
