import { prisma } from "./src/config/prisma.js";

const rows = await prisma.$queryRawUnsafe(`
  SELECT
    migration_name,
    checksum,
    started_at,
    finished_at,
    rolled_back_at,
    applied_steps_count,
    logs
  FROM "_prisma_migrations"
  WHERE migration_name IN (
    '20260928171029_add_billing_foundation',
    '20260929024718_add_billing_webhook_events',
    '20260929041741_add_storage_accounting',
    '20260929042155_add_billing_profile',
    '20260929042539_add_invoice_foundation',
    '20260929091936_add_invoice_payment_unique',
    '20260929094738_add_invoice_sequence'
  )
  ORDER BY started_at
`);

console.log(JSON.stringify(rows, null, 2));

await prisma.$disconnect();
