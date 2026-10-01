import { prisma } from "./src/config/prisma.js";

const rows = await prisma.$queryRawUnsafe(`
  SELECT
    table_name
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN (
      'plans',
      'plan_features',
      'subscriptions',
      'subscription_entitlements',
      'extra_scan_packs',
      'retention_options',
      'billing_webhook_events',
      'payments',
      'payment_items',
      'billing_profiles',
      'invoices',
      'invoice_sequences',
      'invoice_items'
    )
  ORDER BY table_name
`);

console.log(JSON.stringify(rows, null, 2));

await prisma.$disconnect();
