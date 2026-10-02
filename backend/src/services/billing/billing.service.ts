import crypto from "node:crypto";
import { prisma } from "../../config/prisma.js";
import { razorpayService } from "../razorpay/razorpay.service.js";
import { getCommercialPlan } from "./commercial-plan.config.js";
import { scanWalletService } from "../scan-wallet/scan-wallet.service.js";
import { invoiceService } from "../invoice/invoice.service.js";

export interface CreatePlanOrderInput {
  companyId: string;
  planCode: string;
  billingInterval?: "MONTHLY" | "YEARLY";
}

interface InvoicePaymentVerificationRow {
  id: string;
  invoiceNumber: string;
  status: string;
}

interface BillingPaymentRow {
  id: string;
  companyId: string;
  provider: string;
  providerOrderId: string | null;
  providerPaymentId: string | null;
  status: string;
  plan: string;
  billingInterval: string;
  currency: string;
  amountPaise: bigint;
  gstPaise: bigint;
  totalPaise: bigint;
  providerSignature: string | null;
  metadata: unknown;
  failureReason: string | null;
  paidAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

function getPlanPricePaise(
  planCode: string,
  billingInterval: "MONTHLY" | "YEARLY",
): number {
  const plan = planCode.trim().toUpperCase();

  const envName =
    `RAZORPAY_${plan}_${billingInterval}_PRICE_PAISE`;

  const raw = process.env[envName]?.trim();

  if (!raw) {
    throw new Error(`PLAN_PRICE_NOT_CONFIGURED:${plan}:${billingInterval}`);
  }

  const amount = Number(raw);

  if (!Number.isInteger(amount) || amount <= 0) {
    throw new Error(`INVALID_PLAN_PRICE:${plan}:${billingInterval}`);
  }

  return amount;
}

function getGstPercent(): number {
  const raw = process.env.RAZORPAY_GST_PERCENT?.trim();

  if (!raw) {
    return 0;
  }

  const value = Number(raw);

  if (!Number.isFinite(value) || value < 0 || value > 100) {
    throw new Error("INVALID_RAZORPAY_GST_PERCENT");
  }

  return value;
}

function normalizePlanCode(value: string): string {
  return value.trim().toLowerCase();
}

function isSupportedPaidPlan(plan: string): boolean {
  return (
    plan === "starter" ||
    plan === "growth" ||
    plan === "enterprise" ||
    plan === "professional"
  );
}

function getValidityMonths(
  plan: string,
  billingInterval: "MONTHLY" | "YEARLY",
): number {
  const commercialPlan = getCommercialPlan(plan);

  if (commercialPlan) {
    return commercialPlan.validityMonths;
  }

  /*
   * Legacy professional plan.
   *
   * Preserve the existing MONTHLY/YEARLY behavior until
   * the legacy plan is intentionally migrated.
   */
  return billingInterval === "YEARLY" ? 12 : 1;
}

export class BillingService {
  async createPlanOrder(input: CreatePlanOrderInput) {
    const plan = normalizePlanCode(input.planCode);

    if (!isSupportedPaidPlan(plan)) {
      throw new Error(`PLAN_NOT_AVAILABLE:${plan}`);
    }

    const billingInterval = input.billingInterval ?? "MONTHLY";

    /*
     * Commercial plans use fixed validity periods and fixed
     * base prices. Legacy professional continues using the
     * existing MONTHLY/YEARLY environment configuration.
     */
    const commercialPlan = getCommercialPlan(plan);

    const subtotalPaise = commercialPlan
      ? commercialPlan.pricePaise
      : getPlanPricePaise(
          plan,
          billingInterval,
        );

    const validityMonths = getValidityMonths(plan, billingInterval);

    const gstPercent = getGstPercent();

    const gstPaise = Math.round(
      (subtotalPaise * gstPercent) / 100,
    );

    const totalPaise = subtotalPaise + gstPaise;

    const paymentId = crypto.randomUUID();

    const metadata = {
      planCode: plan,
      billingInterval,
      gstPercent,
      validityMonths,
      commercialPlan: Boolean(commercialPlan),
      includedScans: commercialPlan?.includedScans ?? null,
      maxWarehouses: commercialPlan?.maxWarehouses ?? null,
      maxOperators: commercialPlan?.maxOperators ?? null,
      retentionDays: commercialPlan?.retentionDays ?? null,
    };

    await prisma.$executeRawUnsafe(
      `
      INSERT INTO "BillingPayment" (
        "id",
        "companyId",
        "provider",
        "status",
        "plan",
        "billingInterval",
        "currency",
        "amountPaise",
        "gstPaise",
        "totalPaise",
        "metadata",
        "createdAt",
        "updatedAt"
      )
      VALUES (
        $1,
        $2,
        'RAZORPAY',
        'PENDING',
        $3,
        $4,
        'INR',
        $5,
        $6,
        $7,
        $8::jsonb,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
      `,
      paymentId,
      input.companyId,
      plan,
      billingInterval,
      subtotalPaise,
      gstPaise,
      totalPaise,
      JSON.stringify(metadata),
    );

    try {
      const receipt = `ld_${paymentId}`.slice(0, 40);

      const order = await razorpayService.createOrder({
        amountPaise: totalPaise,
        receipt,
        notes: {
          paymentId,
          companyId: input.companyId,
          planCode: plan,
          billingInterval,
          validityMonths: String(validityMonths),
        },
      });

      await prisma.$executeRawUnsafe(
        `
        UPDATE "BillingPayment"
        SET
          "providerOrderId" = $2,
          "updatedAt" = CURRENT_TIMESTAMP
        WHERE "id" = $1
        `,
        paymentId,
        order.id,
      );

      const payment = await this.getPaymentById(paymentId);

      return {
        payment,
        razorpay: {
          keyId: razorpayService.getKeyId(),
          orderId: order.id,
          amount: order.amount,
          currency: order.currency,
        },
        plan: {
          code: plan,
          billingInterval,
          subtotalPaise,
          gstPaise,
          totalPaise,
        },
      };
    } catch (error) {
      await this.markPaymentFailed(
        paymentId,
        error instanceof Error
          ? error.message
          : "Razorpay order creation failed.",
      );

      throw error;
    }
  }

  async verifyAndConfirmPayment(input: {
    companyId: string;
    paymentId: string;
    razorpayPaymentId: string;
    razorpayOrderId: string;
    razorpaySignature: string;
  }) {
    const payment = await prisma.$queryRawUnsafe<
      BillingPaymentRow[]
    >(
      `
      SELECT *
      FROM "BillingPayment"
      WHERE
        "id" = $1
        AND "companyId" = $2
        AND "provider" = 'RAZORPAY'
      LIMIT 1
      `,
      input.paymentId,
      input.companyId,
    );

    const current = payment[0];

    if (!current) {
      throw new Error("PAYMENT_NOT_FOUND");
    }

    if (!current.providerOrderId) {
      throw new Error("PAYMENT_ORDER_NOT_FOUND");
    }

    if (current.providerOrderId !== input.razorpayOrderId) {
      throw new Error("RAZORPAY_ORDER_MISMATCH");
    }

    const validSignature =
      razorpayService.verifyPaymentSignature({
        orderId: input.razorpayOrderId,
        paymentId: input.razorpayPaymentId,
        signature: input.razorpaySignature,
      });

    if (!validSignature) {
      throw new Error("INVALID_RAZORPAY_SIGNATURE");
    }

    const razorpayPayment =
      await razorpayService.fetchPayment(
        input.razorpayPaymentId,
      );

    if (
      String(razorpayPayment.order_id) !==
      current.providerOrderId
    ) {
      throw new Error("RAZORPAY_ORDER_MISMATCH");
    }

    if (
      Number(razorpayPayment.amount) !==
      Number(current.totalPaise)
    ) {
      throw new Error("RAZORPAY_AMOUNT_MISMATCH");
    }

    if (
      String(razorpayPayment.currency).toUpperCase() !==
      "INR"
    ) {
      throw new Error("RAZORPAY_CURRENCY_MISMATCH");
    }

    const status = String(
      razorpayPayment.status,
    ).toLowerCase();

    if (
      status !== "captured" &&
      status !== "authorized"
    ) {
      throw new Error(
        `RAZORPAY_PAYMENT_NOT_SUCCESSFUL:${status}`,
      );
    }

    return this.confirmRazorpayPayment({
      paymentId: current.id,
      razorpayPaymentId: input.razorpayPaymentId,
      razorpaySignature: input.razorpaySignature,
    });
  }

  async confirmRazorpayPayment(input: {
    paymentId: string;
    razorpayPaymentId: string;
    razorpaySignature?: string;
  }) {
    return prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRawUnsafe<
        BillingPaymentRow[]
      >(
        `
        SELECT *
        FROM "BillingPayment"
        WHERE "id" = $1
        LIMIT 1
        `,
        input.paymentId,
      );

      const payment = rows[0];

      if (!payment) {
        throw new Error("PAYMENT_NOT_FOUND");
      }

      if (payment.status === "SUCCESS") {
        await invoiceService.createFromBillingPaymentInTransaction(
          tx,
          payment.companyId,
          payment.id,
        );

        const existingInvoiceRows =
          await tx.$queryRawUnsafe<InvoicePaymentVerificationRow[]>(
            `
            SELECT
              "id",
              "invoiceNumber",
              "status"
            FROM "invoices"
            WHERE "companyId" = $1
              AND "billingPaymentId" = $2
            LIMIT 1
            `,
            payment.companyId,
            payment.id,
          );

        if (existingInvoiceRows.length !== 1) {
          throw new Error("INVOICE_CREATION_FAILED");
        }

        return payment;
      }

      if (
        payment.status !== "PENDING" &&
        payment.status !== "CREATED"
      ) {
        throw new Error(
          `PAYMENT_STATE_INVALID:${payment.status}`,
        );
      }

      const now = new Date();

      /*
       * Commercial plan validity is stored in payment.metadata.
       * This keeps the purchased validity attached to the payment
       * instead of deriving it later from a generic billing interval.
       */
      let validityMonths = 1;

      if (
        payment.metadata &&
        typeof payment.metadata === "object" &&
        "validityMonths" in payment.metadata
      ) {
        const rawValidity = Number(
          (payment.metadata as { validityMonths?: unknown })
            .validityMonths,
        );

        if (
          Number.isInteger(rawValidity) &&
          rawValidity > 0 &&
          rawValidity <= 120
        ) {
          validityMonths = rawValidity;
        }
      }

      const periodEnd = new Date(now);

      periodEnd.setMonth(
        periodEnd.getMonth() + validityMonths,
      );

      /*
       * Activate the company plan in the LIVE database.
       *
       * Live Company.plan is an enum containing:
       * free / starter / professional / enterprise
       */
      await tx.$executeRawUnsafe(
        `
        UPDATE "Company"
        SET
          "plan" = $2::"Plan",
          "updatedAt" = CURRENT_TIMESTAMP
        WHERE "id" = $1
        `,
        payment.companyId,
        payment.plan,
      );

      /*
       * Update the existing billing subscription when present.
       *
       * For an order-based first purchase there may be no subscription
       * row yet. In that case create the local subscription record with
       * no Razorpay Subscription ID because this payment uses a Razorpay
       * Order + Payment flow.
       *
       * Existing Razorpay subscription IDs are preserved.
       */
      const existingSubscriptions = await tx.$queryRawUnsafe<
        Array<{
          id: string;
        }>
      >(
        `
        SELECT
          "id"
        FROM "BillingSubscription"
        WHERE "companyId" = $1
        LIMIT 1
        `,
        payment.companyId,
      );

      if (existingSubscriptions.length > 0) {
        await tx.$executeRawUnsafe(
          `
          UPDATE "BillingSubscription"
          SET
            "plan" = $2,
            "status" = 'active',
            "currentPeriodStart" = $3,
            "currentPeriodEnd" = $4,
            "updatedAt" = CURRENT_TIMESTAMP
          WHERE "companyId" = $1
          `,
          payment.companyId,
          payment.plan,
          now,
          periodEnd,
        );
      } else {
        await tx.$executeRawUnsafe(
          `
          INSERT INTO "BillingSubscription" (
            "id",
            "companyId",
            "razorpaySubId",
            "plan",
            "status",
            "currentPeriodStart",
            "currentPeriodEnd",
            "createdAt",
            "updatedAt"
          )
          VALUES (
            $1,
            $2,
            NULL,
            $3::"Plan",
            'active',
            $4,
            $5,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
          )
          `,
          crypto.randomUUID(),
          payment.companyId,
          payment.plan,
          now,
          periodEnd,
        );
      }

      /*
       * Allocate the purchased commercial plan scan package.
       *
       * The allocation is performed inside the same database transaction
       * as the payment/subscription confirmation.
       *
       * The BillingPayment ID is used as the idempotency key so repeated
       * confirmation/webhook delivery cannot allocate the same package twice.
       *
       * Legacy "professional" remains supported by billing but does not
       * receive a commercial scan allocation because it has no commercial
       * plan definition.
       */
      const normalizedPaymentPlan = normalizePlanCode(payment.plan);
      const commercialPlan = getCommercialPlan(normalizedPaymentPlan);

      if (commercialPlan) {
        const metadata =
          payment.metadata &&
          typeof payment.metadata === "object"
            ? (payment.metadata as {
                includedScans?: unknown;
              })
            : null;

        const metadataIncludedScans = Number(
          metadata?.includedScans ?? commercialPlan.includedScans,
        );

        if (
          !Number.isInteger(metadataIncludedScans) ||
          metadataIncludedScans <= 0
        ) {
          throw new Error(
            `INVALID_INCLUDED_SCANS:${normalizedPaymentPlan}`,
          );
        }

        await scanWalletService.allocateScansInTransaction(tx, {
          companyId: payment.companyId,
          credits: metadataIncludedScans,
          referenceType: "BILLING_PAYMENT",
          referenceId: payment.id,
          idempotencyKey: `billing-payment:${payment.id}:scan-allocation`,
          description: `${normalizedPaymentPlan} plan scan allocation`,
          type: "ALLOCATION",
        });
      }

      const updatedRows = await tx.$queryRawUnsafe<
        BillingPaymentRow[]
      >(
        `
        UPDATE "BillingPayment"
        SET
          "providerPaymentId" = $2,
          "providerSignature" = COALESCE($3, "providerSignature"),
          "status" = 'SUCCESS',
          "paidAt" = $4,
          "failureReason" = NULL,
          "updatedAt" = CURRENT_TIMESTAMP
        WHERE "id" = $1
        RETURNING *
        `,
        payment.id,
        input.razorpayPaymentId,
        input.razorpaySignature ?? null,
        now,
      );

      if (updatedRows.length !== 1) {
        throw new Error("PAYMENT_CONFIRMATION_FAILED");
      }

      await invoiceService.createFromBillingPaymentInTransaction(
        tx,
        payment.companyId,
        payment.id,
      );

      const invoiceRows =
        await tx.$queryRawUnsafe<InvoicePaymentVerificationRow[]>(
          `
          SELECT
            "id",
            "invoiceNumber",
            "status"
          FROM "invoices"
          WHERE "companyId" = $1
            AND "billingPaymentId" = $2
          LIMIT 1
          `,
          payment.companyId,
          payment.id,
        );

      if (invoiceRows.length !== 1) {
        throw new Error("INVOICE_CREATION_FAILED");
      }

      return updatedRows[0];
    });
  }

  async markPaymentFailed(
    paymentId: string,
    failureReason: string,
  ) {
    await prisma.$executeRawUnsafe(
      `
      UPDATE "BillingPayment"
      SET
        "status" = 'FAILED',
        "failureReason" = $2,
        "updatedAt" = CURRENT_TIMESTAMP
      WHERE
        "id" = $1
        AND "status" IN ('PENDING', 'CREATED')
      `,
      paymentId,
      failureReason,
    );
  }

  async getPaymentById(
    paymentId: string,
  ): Promise<BillingPaymentRow | null> {
    const rows = await prisma.$queryRawUnsafe<
      BillingPaymentRow[]
    >(
      `
      SELECT *
      FROM "BillingPayment"
      WHERE "id" = $1
      LIMIT 1
      `,
      paymentId,
    );

    return rows[0] ?? null;
  }
}

export const billingService = new BillingService();




