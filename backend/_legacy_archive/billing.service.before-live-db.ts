import { prisma } from "../../config/prisma.js";
import { razorpayService } from "../razorpay/razorpay.service.js";

export interface CreatePlanOrderInput {
  companyId: string;
  planCode: string;
  billingInterval?: "MONTHLY" | "YEARLY";
}

export class BillingService {
  async createPlanOrder(input: CreatePlanOrderInput) {
    const plan = await prisma.plan.findFirst({
      where: {
        code: input.planCode,
        isActive: true,
      },
    });

    if (!plan) {
      throw new Error("PLAN_NOT_FOUND");
    }

    const billingInterval = input.billingInterval ?? "MONTHLY";

    let subtotalPaise = plan.pricePaise ?? 0;

    if (billingInterval === "MONTHLY" && plan.monthlyPrice != null) {
      subtotalPaise = Math.round(Number(plan.monthlyPrice) * 100);
    }

    if (billingInterval === "YEARLY" && plan.yearlyPrice != null) {
      subtotalPaise = Math.round(Number(plan.yearlyPrice) * 100);
    }

    if (!Number.isInteger(subtotalPaise) || subtotalPaise <= 0) {
      throw new Error("PLAN_PRICE_NOT_CONFIGURED");
    }

    const gstPaise = Math.round(
      (subtotalPaise * plan.gstPercent) / 100,
    );

    const totalPaise = subtotalPaise + gstPaise;

    const payment = await prisma.payment.create({
      data: {
        companyId: input.companyId,
        provider: "RAZORPAY",
        status: "PENDING",
        currency: "INR",
        subtotalPaise,
        gstPaise,
        totalPaise,
        metadata: {
          planCode: plan.code,
          billingInterval,
        },
        items: {
          create: {
            itemType: "PLAN",
            referenceId: plan.id,
            code: plan.code,
            name: plan.name,
            quantity: 1,
            unitPricePaise: subtotalPaise,
            gstPaise,
            totalPaise,
            metadata: {
              billingInterval,
            },
          },
        },
      },
      include: {
        items: true,
      },
    });

    const receipt = `ld_${payment.id}`.slice(0, 40);

    const order = await razorpayService.createOrder({
      amountPaise: totalPaise,
      receipt,
      notes: {
        paymentId: payment.id,
        companyId: input.companyId,
        planCode: plan.code,
        billingInterval,
      },
    });

    const updatedPayment = await prisma.payment.update({
      where: {
        id: payment.id,
      },
      data: {
        providerOrderId: order.id,
      },
      include: {
        items: true,
      },
    });

    return {
      payment: updatedPayment,
      razorpay: {
        keyId: razorpayService.getKeyId(),
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
      },
      plan: {
        id: plan.id,
        code: plan.code,
        name: plan.name,
        billingInterval,
        subtotalPaise,
        gstPaise,
        totalPaise,
      },
    };
  }

  async verifyAndConfirmPayment(input: {
    companyId: string;
    paymentId: string;
    razorpayPaymentId: string;
    razorpayOrderId: string;
    razorpaySignature: string;
  }) {
    const payment = await prisma.payment.findFirst({
      where: {
        id: input.paymentId,
        companyId: input.companyId,
        provider: "RAZORPAY",
      },
      include: {
        items: true,
      },
    });

    if (!payment) {
      throw new Error("PAYMENT_NOT_FOUND");
    }

    if (!payment.providerOrderId) {
      throw new Error("PAYMENT_ORDER_NOT_FOUND");
    }

    if (payment.providerOrderId !== input.razorpayOrderId) {
      throw new Error("RAZORPAY_ORDER_MISMATCH");
    }

    const validSignature = razorpayService.verifyPaymentSignature({
      orderId: input.razorpayOrderId,
      paymentId: input.razorpayPaymentId,
      signature: input.razorpaySignature,
    });

    if (!validSignature) {
      throw new Error("INVALID_RAZORPAY_SIGNATURE");
    }

    const razorpayPayment = await razorpayService.fetchPayment(
      input.razorpayPaymentId,
    );

    if (String(razorpayPayment.order_id) !== payment.providerOrderId) {
      throw new Error("RAZORPAY_ORDER_MISMATCH");
    }

    if (Number(razorpayPayment.amount) !== payment.totalPaise) {
      throw new Error("RAZORPAY_AMOUNT_MISMATCH");
    }

    if (String(razorpayPayment.currency).toUpperCase() !== "INR") {
      throw new Error("RAZORPAY_CURRENCY_MISMATCH");
    }

    const status = String(razorpayPayment.status).toLowerCase();

    if (status !== "captured" && status !== "authorized") {
      throw new Error(`RAZORPAY_PAYMENT_NOT_SUCCESSFUL:${status}`);
    }

    return this.confirmRazorpayPayment({
      paymentId: payment.id,
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
      const payment = await tx.payment.findUnique({
        where: {
          id: input.paymentId,
        },
        include: {
          items: true,
        },
      });

      if (!payment) {
        throw new Error("PAYMENT_NOT_FOUND");
      }

      if (payment.status === "SUCCESS") {
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

      const planItem = payment.items.find(
        (item) => item.itemType === "PLAN",
      );

      if (!planItem?.referenceId) {
        throw new Error("PLAN_PAYMENT_ITEM_MISSING");
      }

      const plan = await tx.plan.findUnique({
        where: {
          id: planItem.referenceId,
        },
      });

      if (!plan) {
        throw new Error("PLAN_NOT_FOUND");
      }

      const metadata =
        payment.metadata &&
        typeof payment.metadata === "object" &&
        !Array.isArray(payment.metadata)
          ? (payment.metadata as Record<string, unknown>)
          : {};

      const billingInterval =
        metadata.billingInterval === "YEARLY"
          ? "YEARLY"
          : "MONTHLY";

      const now = new Date();

      const currentPeriodEnd = new Date(now);

      if (billingInterval === "YEARLY") {
        currentPeriodEnd.setFullYear(
          currentPeriodEnd.getFullYear() + 1,
        );
      } else {
        currentPeriodEnd.setMonth(
          currentPeriodEnd.getMonth() + 1,
        );
      }

      const subscription = await tx.subscription.upsert({
        where: {
          companyId: payment.companyId,
        },
        create: {
          companyId: payment.companyId,
          planId: plan.id,
          status: "ACTIVE",
          billingInterval,
          provider: "RAZORPAY",
          currentPeriodStart: now,
          currentPeriodEnd,
          trialEnd: null,
        },
        update: {
          planId: plan.id,
          status: "ACTIVE",
          billingInterval,
          provider: "RAZORPAY",
          currentPeriodStart: now,
          currentPeriodEnd,
          cancelledAt: null,
        },
      });

      const updatedPayment = await tx.payment.update({
        where: {
          id: payment.id,
        },
        data: {
          subscriptionId: subscription.id,
          providerPaymentId: input.razorpayPaymentId,
          providerSignature:
            input.razorpaySignature ?? payment.providerSignature,
          status: "SUCCESS",
          paidAt: now,
          failureReason: null,
        },
        include: {
          items: true,
          subscription: true,
        },
      });

      return updatedPayment;
    });
  }

  async markPaymentFailed(
    paymentId: string,
    failureReason: string,
  ) {
    return prisma.payment.updateMany({
      where: {
        id: paymentId,
        status: {
          in: ["PENDING", "CREATED"],
        },
      },
      data: {
        status: "FAILED",
        failureReason,
      },
    });
  }
}

export const billingService = new BillingService();
