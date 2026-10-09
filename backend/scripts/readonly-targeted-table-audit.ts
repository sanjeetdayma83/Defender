import { prisma } from "../src/config/prisma.js";

const names = [
  "companies", "users", "warehouses",
  "Company", "User", "Warehouse",
  "BillingPayment", "BillingWebhookEvent", "BillingSubscription",
  "Recording", "RecordingSegment", "Evidence", "AuditLog", "audit_logs",
  "storage_objects", "invoice_sequences", "invoices", "invoice_items",
  "user_invitations", "user_warehouse_assignments",
  "Order", "order_identifiers", "extra_scan_packs", "scan_topup_packs",
  "platform_settings", "scan_wallets", "scan_transactions",
  "plan_configurations"
];

try {
  const tables = await prisma.$queryRaw<Array<{
    table_schema: string;
    table_name: string;
  }>>`
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = ANY(${names})
    ORDER BY table_name
  `;

  console.log("\n===== TABLE EXISTENCE =====");
  const existing = new Set(tables.map(t => t.table_name));

  for (const name of names) {
    console.log(`${existing.has(name) ? "EXISTS" : "MISSING"}  public.${name}`);
  }

  const columns = await prisma.$queryRaw<Array<{
    table_name: string;
    column_name: string;
    data_type: string;
    is_nullable: string;
    udt_name: string;
  }>>`
    SELECT table_name, column_name, data_type, is_nullable, udt_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = ANY(${names})
    ORDER BY table_name, ordinal_position
  `;

  console.log("\n===== EXISTING TABLE COLUMNS =====");
  for (const c of columns) {
    console.log(
      `${c.table_name}.${c.column_name} | ${c.data_type} | udt=${c.udt_name} | nullable=${c.is_nullable}`
    );
  }

  console.log("\nREAD-ONLY AUDIT COMPLETE");
} finally {
  await prisma.$disconnect();
}
