import fs from "node:fs";

const path = "./src/services/billing/billing.service.ts";

const content = fs.readFileSync(path, "utf8");

const startMarker =
`      /*
       * Keep the existing BillingSubscription record intact.`;

const endMarker =
`      const updatedRows = await tx.$queryRawUnsafe<`;

const start = content.indexOf(startMarker);
const end = content.indexOf(endMarker);

if (start === -1) {
  throw new Error("START_MARKER_NOT_FOUND — file was NOT modified.");
}

if (end === -1) {
  throw new Error("END_MARKER_NOT_FOUND — file was NOT modified.");
}

if (end <= start) {
  throw new Error("INVALID_MARKER_ORDER — file was NOT modified.");
}

const replacement = `      /*
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
        \`
        SELECT
          "id"
        FROM "BillingSubscription"
        WHERE "companyId" = $1
        LIMIT 1
        \`,
        payment.companyId,
      );

      if (existingSubscriptions.length > 0) {
        await tx.$executeRawUnsafe(
          \`
          UPDATE "BillingSubscription"
          SET
            "plan" = $2,
            "status" = 'active',
            "currentPeriodStart" = $3,
            "currentPeriodEnd" = $4,
            "updatedAt" = CURRENT_TIMESTAMP
          WHERE "companyId" = $1
          \`,
          payment.companyId,
          payment.plan,
          now,
          periodEnd,
        );
      } else {
        await tx.$executeRawUnsafe(
          \`
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
          \`,
          crypto.randomUUID(),
          payment.companyId,
          payment.plan,
          now,
          periodEnd,
        );
      }

`;

const newContent =
  content.slice(0, start) +
  replacement +
  content.slice(end);

if (!newContent.includes("export const billingService = new BillingService();")) {
  throw new Error(
    "SAFETY CHECK FAILED — billingService export disappeared. File was NOT modified.",
  );
}

fs.writeFileSync(path, newContent, "utf8");

console.log("SUCCESS: BillingSubscription upsert patch applied.");
