import "dotenv/config";

import crypto from "node:crypto";

const webhookUrl =
  "http://localhost:4000/api/v1/billing/webhook/razorpay";

const eventId = `test_evt_${Date.now()}`;

const payload = {
  entity: "event",
  account_id: "test_account",
  event: "payment.captured",
  contains: ["payment"],
  payload: {
    payment: {
      entity: {
        id: "pay_TiMYQXlfdWxLcH",
        order_id: "order_TiMRs0j5opbuUz",
        amount: 100,
        currency: "INR",
        status: "captured",
      },
    },
  },
};

const rawBody = JSON.stringify(payload);

const secret = process.env.RAZORPAY_WEBHOOK_SECRET?.trim();

if (!secret) {
  throw new Error("RAZORPAY_WEBHOOK_SECRET is missing.");
}

const signature = crypto
  .createHmac("sha256", secret)
  .update(rawBody)
  .digest("hex");

async function sendWebhook(label: string) {
  console.log("");
  console.log("============================================");
  console.log(` ${label}`);
  console.log("============================================");

  const response = await fetch(webhookUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-razorpay-signature": signature,
      "x-razorpay-event-id": eventId,
    },
    body: rawBody,
  });

  const text = await response.text();

  console.log("HTTP Status :", response.status);
  console.log("Response    :", text);

  return {
    status: response.status,
    text,
  };
}

try {
  console.log("============================================");
  console.log(" RAZORPAY WEBHOOK TEST");
  console.log("============================================");
  console.log("Webhook URL :", webhookUrl);
  console.log("Event ID    :", eventId);
  console.log("Event       : payment.captured");
  console.log("Payment ID  : pay_TiMYQXlfdWxLcH");
  console.log("Order ID    : order_TiMRs0j5opbuUz");

  const first = await sendWebhook("FIRST WEBHOOK DELIVERY");

  if (first.status < 200 || first.status >= 300) {
    throw new Error(
      `First webhook delivery failed with HTTP ${first.status}`,
    );
  }

  const second = await sendWebhook("DUPLICATE WEBHOOK DELIVERY");

  if (second.status < 200 || second.status >= 300) {
    throw new Error(
      `Duplicate webhook delivery failed with HTTP ${second.status}`,
    );
  }

  console.log("");
  console.log("============================================");
  console.log(" WEBHOOK TEST COMPLETED");
  console.log("============================================");
  console.log("First delivery    : PASSED");
  console.log("Duplicate delivery: PASSED");
  console.log("============================================");
} catch (error) {
  console.error("");
  console.error("WEBHOOK TEST FAILED");
  console.error("--------------------------------------------");
  console.error(error);
  process.exitCode = 1;
}
