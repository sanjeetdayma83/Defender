import { prisma } from "./src/config/prisma.js";

async function main() {
  console.log("===== CREATING SCAN WALLET TABLES =====");

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS scan_wallets (
      id TEXT PRIMARY KEY,
      "companyId" TEXT NOT NULL UNIQUE,
      balance INTEGER NOT NULL DEFAULT 0,
      "lifetimeAllocated" INTEGER NOT NULL DEFAULT 0,
      "lifetimeConsumed" INTEGER NOT NULL DEFAULT 0,
      "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      "updatedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

      CONSTRAINT scan_wallets_company_fk
        FOREIGN KEY ("companyId")
        REFERENCES "Company"(id)
        ON DELETE CASCADE
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS scan_transactions (
      id TEXT PRIMARY KEY,
      "walletId" TEXT NOT NULL,
      "companyId" TEXT NOT NULL,
      type TEXT NOT NULL,
      credits INTEGER NOT NULL,
      "balanceAfter" INTEGER NOT NULL,
      "referenceType" TEXT,
      "referenceId" TEXT,
      "idempotencyKey" TEXT UNIQUE,
      description TEXT,
      "createdAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

      CONSTRAINT scan_transactions_wallet_fk
        FOREIGN KEY ("walletId")
        REFERENCES scan_wallets(id)
        ON DELETE CASCADE,

      CONSTRAINT scan_transactions_company_fk
        FOREIGN KEY ("companyId")
        REFERENCES "Company"(id)
        ON DELETE CASCADE,

      CONSTRAINT scan_transactions_type_check
        CHECK (
          type IN (
            'ALLOCATION',
            'CONSUMPTION',
            'TOPUP',
            'REFUND',
            'ADJUSTMENT',
            'EXPIRATION'
          )
        ),

      CONSTRAINT scan_transactions_credits_check
        CHECK (credits <> 0)
    );
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS scan_transactions_wallet_created_idx
      ON scan_transactions ("walletId", "createdAt" DESC);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS scan_transactions_company_created_idx
      ON scan_transactions ("companyId", "createdAt" DESC);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS scan_transactions_type_idx
      ON scan_transactions (type);
  `);

  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS scan_transactions_reference_idx
      ON scan_transactions ("referenceType", "referenceId");
  `);

  console.log("===== SCAN WALLET TABLES CREATED =====");

  const tables = await prisma.$queryRawUnsafe<any[]>(`
    SELECT
      table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN (
        'scan_wallets',
        'scan_transactions'
      )
    ORDER BY table_name;
  `);

  console.table(tables);

  const walletColumns = await prisma.$queryRawUnsafe<any[]>(`
    SELECT
      table_name,
      column_name,
      data_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name IN (
        'scan_wallets',
        'scan_transactions'
      )
    ORDER BY table_name, ordinal_position;
  `);

  console.log("===== SCAN WALLET COLUMNS =====");
  console.table(walletColumns);
}

main()
  .catch((error) => {
    console.error("SCAN WALLET SETUP FAILED");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
