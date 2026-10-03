import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { scanWalletService } from "../../services/wallet/scan-wallet.service.js";
import { companyContextService } from "../../services/identity/company-context.service.js";

export async function getWallet(
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

  const wallet = await scanWalletService.get(company.id);

  res.json({
    success: true,
    data: wallet,
  });
}

export async function consumeCredits(
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

  const credits = Number(req.body?.credits ?? 1);

  if (!Number.isInteger(credits) || credits <= 0) {
    res.status(400).json({
      success: false,
      message: "credits must be a positive integer.",
    });
    return;
  }

  try {
    const transaction = await scanWalletService.consume(
      company.id,
      credits,
      req.body?.description ?? "Packing scan",
      req.body?.referenceType,
      req.body?.referenceId,
      req.body?.idempotencyKey,
    );

    res.json({
      success: true,
      data: transaction,
    });
  } catch (error) {
    if (
      error instanceof Error &&
      error.message === "INSUFFICIENT_SCAN_CREDITS"
    ) {
      res.status(409).json({
        success: false,
        code: "INSUFFICIENT_SCAN_CREDITS",
        message: "Insufficient scan credits.",
      });
      return;
    }

    throw error;
  }
}

export async function topUpCredits(
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

  if (!["PLATFORM_ADMIN", "OWNER", "ADMIN"].includes(user.role)) {
    res.status(403).json({
      success: false,
      message: "You do not have permission to top up credits.",
    });
    return;
  }

  const credits = Number(req.body?.credits);

  if (!Number.isInteger(credits) || credits <= 0) {
    res.status(400).json({
      success: false,
      message: "credits must be a positive integer.",
    });
    return;
  }

  const transaction = await scanWalletService.topUp(
    company.id,
    credits,
    req.body?.description ?? "Scan credit top-up",
    req.body?.referenceType,
    req.body?.referenceId,
    req.body?.idempotencyKey,
  );

  res.json({
    success: true,
    data: transaction,
  });
}

export async function refundCredits(
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

  if (!["PLATFORM_ADMIN", "OWNER", "ADMIN"].includes(user.role)) {
    res.status(403).json({
      success: false,
      message: "You do not have permission to refund credits.",
    });
    return;
  }

  const credits = Number(req.body?.credits);

  if (!Number.isInteger(credits) || credits <= 0) {
    res.status(400).json({
      success: false,
      message: "credits must be a positive integer.",
    });
    return;
  }

  const transaction = await scanWalletService.refund(
    company.id,
    credits,
    req.body?.description ?? "Scan credit refund",
    req.body?.referenceType,
    req.body?.referenceId,
    req.body?.idempotencyKey,
  );

  res.json({
    success: true,
    data: transaction,
  });
}
