import { prisma } from "./src/config/prisma.js";

async function main() {
  const tables = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN (
        'scan_wallets',
        'scan_transactions',
        'plans',
        'subscriptions',
        'Plan',
        'Subscription',
        'ScanWallet',
        'ScanTransaction'
      )
    ORDER BY table_name
    `,
  );

  console.log("===== EXISTING SCAN/BILLING TABLES =====");
  console.table(tables);

  const companies = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT
      id,
      "companyName",
      plan::text AS plan,
      status::text AS status
    FROM "Company"
    ORDER BY "createdAt"
    `,
  );

  console.log("===== COMPANIES =====");
  console.table(companies);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
