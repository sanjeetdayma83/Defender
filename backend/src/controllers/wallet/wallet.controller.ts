import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { scanWalletService } from "../../services/scan-wallet/scan-wallet.service.js";
import { companyContextService } from "../../services/identity/company-context.service.js";

function jsonSafe<T>(value: T): T {
  return JSON.parse(
    JSON.stringify(value, (_key, item) =>
      typeof item === "bigint" ? Number(item) : item,
    ),
  ) as T;
}

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

  const wallet = await scanWalletService.getOrCreateWallet(company.id);

  res.json({
    success: true,
    data: jsonSafe(wallet),
  });
}

export async function getWalletTransactions(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const firebaseUid = req.firebaseUser?.uid;

    if (!firebaseUid) {
      res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
      return;
    }

    const { company } = await companyContextService.getCompany(firebaseUid);

    const rawLimit = Number(req.query.limit ?? 50);

    const limit =
      Number.isFinite(rawLimit) && rawLimit > 0
        ? Math.min(Math.trunc(rawLimit), 500)
        : 50;

    const transactions = await scanWalletService.getTransactions(
      company.id,
      limit,
    );

    res.json({
      success: true,
      data: {
        items: jsonSafe(transactions),
        total: transactions.length,
      },
    });
  } catch (error) {
    console.error("Wallet transactions lookup failed:", error);

    res.status(500).json({
      success: false,
      message:
        error instanceof Error
          ? error.message
          : "Unable to load wallet transactions.",
    });
  }
}
