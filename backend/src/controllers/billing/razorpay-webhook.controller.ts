import crypto from "node:crypto";
import type { Request, Response } from "express";
import { prisma } from "../../config/prisma.js";
import { razorpayService } from "../../services/razorpay/razorpay.service.js";
import { billingService } from "../../services/billing/billing.service.js";

type RawBodyRequest = Request & {
  rawBody?: Buffer;
};

interface BillingWebhookEventRow {
  id: string;
  provider: string;
  eventId: string;
  eventType: string;
  processed: boolean;
  processedAt: Date | null;
  failureReason: string | null;
}

interface BillingPaymentLookup {
  id: string;
  status: string;
  providerOrderId: string | null;
  providerPaymentId: string | null;
}

function getPaymentId(payload: any): string | null {
  return payload?.payload?.payment?.entity?.id ?? null;
}

function getOrderId(payload: any): string | null {
  return (
    payload?.payload?.payment?.entity?.order_id ??
    payload?.payload?.order?.entity?.id ??
    null
  );
}

export async function razorpayWebhook(
  req: RawBodyRequest,
  res: Response,
): Promise<void> {
  const signature = String(
    req.headers["x-razorpay-signature"] ?? "",
  ).trim();

  const eventId = String(
    req.headers["x-razorpay-event-id"] ?? "",
  ).trim();

  if (!req.rawBody) {
    res.status(500).json({
      success: false,
      message: "RAZORPAY_RAW_BODY_MISSING",
    });
    return;
  }

  if (!signature) {
    res.status(400).json({
      success: false,
      message: "Razorpay signature header is required.",
    });
    return;
  }

  if (!eventId) {
    res.status(400).json({
      success: false,
      message: "Razorpay event ID header is required.",
    });
    return;
  }

  try {
    /*
     * IMPORTANT:
     * Signature is calculated against the exact raw request body.
     */
    const valid = razorpayService.verifyWebhookSignature(
      req.rawBody,
      signature,
    );

    if (!valid) {
      res.status(400).json({
        success: false,
        message: "Invalid Razorpay webhook signature.",
      });
      return;
    }

    const payload = JSON.parse(
      req.rawBody.toString("utf8"),
    );

    const eventType = String(
      payload?.event ?? "unknown",
    );

    /*
     * ----------------------------------------------------------
     * IDEMPOTENCY
     * ----------------------------------------------------------
     */

    const id = crypto.randomUUID();

    const created =
      await prisma.$queryRawUnsafe<BillingWebhookEventRow[]>(
        `
        INSERT INTO "BillingWebhookEvent" (
          "id",
          "provider",
          "eventId",
          "eventType",
          "payload",
          "processed",
          "createdAt",
          "updatedAt"
        )
        VALUES (
          $1,
          'RAZORPAY',
          $2,
          $3,
          $4::jsonb,
          FALSE,
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        )
        ON CONFLICT ("provider", "eventId")
        DO NOTHING
        RETURNING
          "id",
          "provider",
          "eventId",
          "eventType",
          "processed",
          "processedAt",
          "failureReason"
        `,
        id,
        eventId,
        eventType,
        JSON.stringify(payload),
      );

    let webhookEvent = created[0];

    if (!webhookEvent) {
      const existing =
        await prisma.$queryRawUnsafe<BillingWebhookEventRow[]>(
          `
          SELECT
            "id",
            "provider",
            "eventId",
            "eventType",
            "processed",
            "processedAt",
            "failureReason"
          FROM "BillingWebhookEvent"
          WHERE
            "provider" = 'RAZORPAY'
            AND "eventId" = $1
          LIMIT 1
          `,
          eventId,
        );

      webhookEvent = existing[0];

      if (webhookEvent?.processed) {
        res.json({
          success: true,
          duplicate: true,
          message: "Webhook already processed.",
        });
        return;
      }
    }

    if (!webhookEvent) {
      throw new Error(
        "Unable to create or retrieve Razorpay webhook event.",
      );
    }

    try {
      const paymentId = getPaymentId(payload);
      const orderId = getOrderId(payload);

      /*
       * --------------------------------------------------------
       * PAYMENT CAPTURED / ORDER PAID
       * --------------------------------------------------------
       */

      if (
        eventType === "payment.captured" ||
        eventType === "order.paid"
      ) {
        let payment:
          | BillingPaymentLookup
          | undefined;

        if (paymentId) {
          const paymentRows =
            await prisma.$queryRawUnsafe<
              BillingPaymentLookup[]
            >(
              `
              SELECT
                "id",
                "status",
                "providerOrderId",
                "providerPaymentId"
              FROM "BillingPayment"
              WHERE
                "provider" = 'RAZORPAY'
                AND "providerPaymentId" = $1
              LIMIT 1
              `,
              paymentId,
            );

          payment = paymentRows[0];
        }

        if (!payment && orderId) {
          const paymentRows =
            await prisma.$queryRawUnsafe<
              BillingPaymentLookup[]
            >(
              `
              SELECT
                "id",
                "status",
                "providerOrderId",
                "providerPaymentId"
              FROM "BillingPayment"
              WHERE
                "provider" = 'RAZORPAY'
                AND "providerOrderId" = $1
              LIMIT 1
              `,
              orderId,
            );

          payment = paymentRows[0];
        }

        if (
          payment &&
          payment.status !== "SUCCESS" &&
          paymentId
        ) {
          await billingService.confirmRazorpayPayment({
            paymentId: payment.id,
            razorpayPaymentId: paymentId,
          });
        }
      }

      /*
       * --------------------------------------------------------
       * PAYMENT FAILED
       * --------------------------------------------------------
       */

      if (
        eventType === "payment.failed" &&
        (paymentId || orderId)
      ) {
        let payment: BillingPaymentLookup | undefined;

        if (paymentId) {
          const paymentRows =
            await prisma.$queryRawUnsafe<
              BillingPaymentLookup[]
            >(
              `
              SELECT
                "id",
                "status",
                "providerOrderId",
                "providerPaymentId"
              FROM "BillingPayment"
              WHERE
                "provider" = 'RAZORPAY'
                AND "providerPaymentId" = $1
              LIMIT 1
              `,
              paymentId,
            );

          payment = paymentRows[0];
        }

        if (!payment && orderId) {
          const paymentRows =
            await prisma.$queryRawUnsafe<
              BillingPaymentLookup[]
            >(
              `
              SELECT
                "id",
                "status",
                "providerOrderId",
                "providerPaymentId"
              FROM "BillingPayment"
              WHERE
                "provider" = 'RAZORPAY'
                AND "providerOrderId" = $1
              LIMIT 1
              `,
              orderId,
            );

          payment = paymentRows[0];
        }

        if (payment) {
          const reason =
            payload?.payload?.payment?.entity
              ?.error_description ??
            payload?.payload?.payment?.entity
              ?.error_reason ??
            "Razorpay payment failed.";

          await billingService.markPaymentFailed(
            payment.id,
            String(reason),
          );
        }
      }

      /*
       * --------------------------------------------------------
       * MARK WEBHOOK PROCESSED
       * --------------------------------------------------------
       */

      await prisma.$executeRawUnsafe(
        `
        UPDATE "BillingWebhookEvent"
        SET
          "processed" = TRUE,
          "processedAt" = CURRENT_TIMESTAMP,
          "failureReason" = NULL,
          "updatedAt" = CURRENT_TIMESTAMP
        WHERE "id" = $1
        `,
        webhookEvent.id,
      );

      res.json({
        success: true,
        received: true,
        event: eventType,
      });
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : "Webhook processing failed.";

      await prisma.$executeRawUnsafe(
        `
        UPDATE "BillingWebhookEvent"
        SET
          "failureReason" = $2,
          "updatedAt" = CURRENT_TIMESTAMP
        WHERE "id" = $1
        `,
        webhookEvent.id,
        message,
      );

      console.error(
        "Razorpay webhook processing failed:",
        error,
      );

      res.status(500).json({
        success: false,
        message,
      });
    }
  } catch (error) {
    console.error(
      "Razorpay webhook failed:",
      error,
    );

    res.status(500).json({
      success: false,
      message:
        error instanceof Error
          ? error.message
          : "Unable to process Razorpay webhook.",
    });
  }
}


