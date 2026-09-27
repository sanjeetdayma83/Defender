import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { productService } from "../../services/products/product.service.js";

export async function listProducts(
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

  const search = String(req.query.search ?? "").trim() || undefined;

  const products = await productService.list(company.id, search);

  res.json({
    success: true,
    data: products,
  });
}

export async function getProduct(
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

  const product = await productService.get(company.id, String(req.params.id));

  if (!product) {
    res.status(404).json({
      success: false,
      message: "Product not found.",
    });
    return;
  }

  res.json({
    success: true,
    data: product,
  });
}
