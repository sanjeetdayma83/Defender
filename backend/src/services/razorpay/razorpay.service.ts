import crypto from "node:crypto";
import Razorpay from "razorpay";

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

export interface RazorpayOrderInput {
  amountPaise: number;
  receipt: string;
  notes?: Record<string, string>;
}

export class RazorpayService {
  private getClient(): Razorpay {
    return new Razorpay({
      key_id: requiredEnv("RAZORPAY_KEY_ID"),
      key_secret: requiredEnv("RAZORPAY_KEY_SECRET"),
    });
  }

  getKeyId(): string {
    return requiredEnv("RAZORPAY_KEY_ID");
  }

  isConfigured(): boolean {
    return Boolean(
      process.env.RAZORPAY_KEY_ID?.trim() &&
        process.env.RAZORPAY_KEY_SECRET?.trim(),
    );
  }

  async createOrder(input: RazorpayOrderInput) {
    if (!Number.isInteger(input.amountPaise) || input.amountPaise <= 0) {
      throw new Error("Razorpay order amount must be a positive integer.");
    }

    if (!input.receipt.trim()) {
      throw new Error("Razorpay order receipt is required.");
    }

    return this.getClient().orders.create({
      amount: input.amountPaise,
      currency: "INR",
      receipt: input.receipt.trim(),
      notes: input.notes ?? {},
    });
  }

  async fetchPayment(paymentId: string) {
    if (!paymentId.trim()) {
      throw new Error("Razorpay payment ID is required.");
    }

    return this.getClient().payments.fetch(paymentId.trim());
  }

  verifyPaymentSignature(input: {
    orderId: string;
    paymentId: string;
    signature: string;
  }): boolean {
    const secret = requiredEnv("RAZORPAY_KEY_SECRET");

    const generated = crypto
      .createHmac("sha256", secret)
      .update(`${input.orderId}|${input.paymentId}`)
      .digest("hex");

    return this.safeCompare(generated, input.signature);
  }

  verifyWebhookSignature(
    rawBody: Buffer | string,
    signature: string,
  ): boolean {
    const secret = requiredEnv("RAZORPAY_WEBHOOK_SECRET");

    const generated = crypto
      .createHmac("sha256", secret)
      .update(rawBody)
      .digest("hex");

    return this.safeCompare(generated, signature);
  }

  private safeCompare(left: string, right: string): boolean {
    const leftBuffer = Buffer.from(left, "utf8");
    const rightBuffer = Buffer.from(right, "utf8");

    if (leftBuffer.length !== rightBuffer.length) {
      return false;
    }

    return crypto.timingSafeEqual(leftBuffer, rightBuffer);
  }
}

export const razorpayService = new RazorpayService();
