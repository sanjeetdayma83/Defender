import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.$queryRawUnsafe<Array<{
    table_name: string;
  }>>(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('BillingPayment', 'BillingWebhookEvent')
    ORDER BY table_name
  `);

  console.table(rows);
} finally {
  await prisma.$disconnect();
}
