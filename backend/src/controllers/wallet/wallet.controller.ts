import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { scanWalletService } from "../../services/scan-wallet/scan-wallet.service.js";
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

  const wallet = await scanWalletService.getWallet(company.id);

  res.json({
    success: true,
    data: wallet,
  });
}


