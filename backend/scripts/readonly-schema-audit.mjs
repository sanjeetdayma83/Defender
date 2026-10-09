import "dotenv/config";
import pg from "pg";

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});

const tables = [
  "Company",
  "User",
  "Warehouse",
  "Order",
  "Recording",
  "RecordingSegment",
  "Evidence",
  "Claim",
  "Return",
  "BillingPayment",
  "BillingSubscription",
  "BillingWebhookEvent",
  "AuditLog",
  "scan_wallets",
  "scan_transactions",
  "invoices",
  "invoice_items"
];

await client.connect();

for (const table of tables) {
  console.log(`\n===== ${table} =====`);

  const result = await client.query(`
    SELECT
      column_name,
      data_type,
      is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = $1
    ORDER BY ordinal_position
  `, [table]);

  console.table(result.rows);
}

await client.end();
