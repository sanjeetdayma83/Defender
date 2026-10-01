import { prisma } from "./src/config/prisma.js";

async function main() {
  const companyId = "af91a0db-c225-4d61-bc6c-55659eb9edc9";

  const company = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyName",
      plan::text AS plan,
      status::text AS status
    FROM "Company"
    WHERE id = $1
    `,
    companyId,
  );

  const subscriptions = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyId",
      "razorpaySubId",
      plan::text AS plan,
      status,
      "currentPeriodStart",
      "currentPeriodEnd"
    FROM "BillingSubscription"
    WHERE "companyId" = $1
    `,
    companyId,
  );

  const wallets = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyId",
      balance,
      "lifetimeAllocated",
      "lifetimeConsumed"
    FROM scan_wallets
    WHERE "companyId" = $1
    `,
    companyId,
  );

  console.log("===== COMPANY =====");
  console.table(company);

  console.log("===== BILLING SUBSCRIPTION =====");
  console.table(subscriptions);

  console.log("===== SCAN WALLET =====");
  console.table(wallets);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
