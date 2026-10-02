import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { billingService } from "../../services/billing/billing.service.js";
import { invoicePdfService } from "../../services/invoice/invoice-pdf.service.js";

async function getCompany(
  req: AuthenticatedRequest,
  requireBillingAdmin = false,
) {
  const uid = req.firebaseUser?.uid;

  if (!uid) {
    throw new Error("AUTHENTICATION_REQUIRED");
  }

  const context = await companyContextService.getCompany(uid);

  if (!context.user.isActive) {
    throw new Error("USER_INACTIVE");
  }

  if (!context.company.isActive) {
    throw new Error("COMPANY_INACTIVE");
  }

  if (
    requireBillingAdmin &&
    String(context.user.role).toLowerCase() !== "company_admin"
  ) {
    throw new Error("BILLING_ADMIN_REQUIRED");
  }

  return context;
}

export async function createRazorpayOrder(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { company } = await getCompany(req, true);

    const planCode = String(req.body?.planCode ?? "").trim().toLowerCase();

    const rawBillingInterval = String(
      req.body?.billingInterval ?? "",
    ).trim().toUpperCase();

    const billingInterval =
      rawBillingInterval === "YEARLY"
        ? "YEARLY"
        : "MONTHLY";

    if (!planCode) {
      res.status(400).json({
        success: false,
        message: "planCode is required.",
      });
      return;
    }

    const allowedPlans = new Set([
      "starter",
      "growth",
      "enterprise",
      "professional",
    ]);

    if (!allowedPlans.has(planCode)) {
      res.status(400).json({
        success: false,
        message:
          "planCode must be starter, growth, enterprise or professional.",
      });
      return;
    }

    const result = await billingService.createPlanOrder({
      companyId: company.id,
      planCode,
      billingInterval,
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Razorpay order creation failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to create Razorpay order.";

    const status =
      message === "PLAN_NOT_FOUND"
        ? 404
        : message === "AUTHENTICATION_REQUIRED"
          ? 401
          : message === "BILLING_ADMIN_REQUIRED"
            ? 403
            : message === "USER_INACTIVE" || message === "COMPANY_INACTIVE"
              ? 403
              : 400;

    res.status(status).json({
      success: false,
      message,
    });
  }
}

export async function verifyRazorpayPayment(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { company } = await getCompany(req, true);

    const paymentId = String(req.body?.paymentId ?? "").trim();

    const razorpayPaymentId = String(
      req.body?.razorpayPaymentId ?? "",
    ).trim();

    const razorpayOrderId = String(
      req.body?.razorpayOrderId ?? "",
    ).trim();

    const razorpaySignature = String(
      req.body?.razorpaySignature ?? "",
    ).trim();

    if (
      !paymentId ||
      !razorpayPaymentId ||
      !razorpayOrderId ||
      !razorpaySignature
    ) {
      res.status(400).json({
        success: false,
        message:
          "paymentId, razorpayPaymentId, razorpayOrderId and razorpaySignature are required.",
      });
      return;
    }

    const result = await billingService.verifyAndConfirmPayment({
      companyId: company.id,
      paymentId,
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Razorpay payment verification failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to verify Razorpay payment.";

    const status =
      message === "PAYMENT_NOT_FOUND"
        ? 404
        : message === "AUTHENTICATION_REQUIRED"
          ? 401
          : message === "BILLING_ADMIN_REQUIRED"
            ? 403
            : message === "USER_INACTIVE" || message === "COMPANY_INACTIVE"
              ? 403
              : 400;

    res.status(status).json({
      success: false,
      message,
    });
  }
}

export async function getInvoicePdf(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  try {
    const { company } = await getCompany(req, true);
    const invoiceId = String(req.params.invoiceId ?? "").trim();

    if (!invoiceId) {
      res.status(400).json({
        success: false,
        message: "invoiceId is required.",
      });
      return;
    }

    const result = await invoicePdfService.generateOrGet(
      company.id,
      invoiceId,
    );

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Invoice PDF generation failed:", error);

    const message =
      error instanceof Error
        ? error.message
        : "Unable to generate invoice PDF.";

    const status =
      message === "AUTHENTICATION_REQUIRED"
        ? 401
        : message === "BILLING_ADMIN_REQUIRED"
          ? 403
          : message === "USER_INACTIVE" || message === "COMPANY_INACTIVE"
            ? 403
            : message === "INVOICE_NOT_FOUND"
              ? 404
              : 500;

    res.status(status).json({
      success: false,
      message:
        message === "INVOICE_NOT_FOUND"
          ? "Invoice not found."
          : status === 401
            ? "Authentication required."
            : "Unable to generate invoice PDF.",
    });
  }
}

