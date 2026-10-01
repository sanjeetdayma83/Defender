import { prisma } from "./src/config/prisma.js";
import { scanWalletService } from "./src/services/scan-wallet/scan-wallet.service.js";

const COMPANY_ID = "af91a0db-c225-4d61-bc6c-55659eb9edc9";

async function main() {
  console.log("========================================");
  console.log(" SCAN WALLET SERVICE TEST");
  console.log("========================================");

  console.log("\n[1] Creating / loading wallet...");
  const wallet = await scanWalletService.getOrCreateWallet(COMPANY_ID);
  console.table(wallet);

  console.log("\n[2] Allocating 100 scans...");
  const allocation = await scanWalletService.allocateScans({
    companyId: COMPANY_ID,
    credits: 100,
    referenceType: "TEST",
    referenceId: "wallet-test-001",
    idempotencyKey: "wallet-test-allocation-001",
    description: "Scan wallet service test allocation",
  });

  console.log("Already processed:", allocation.alreadyProcessed);
  console.log("Balance:", allocation.wallet.balance);
  console.log("Allocated:", allocation.transaction.credits);

  console.log("\n[3] Consuming 1 scan...");
  const consumption1 = await scanWalletService.consumeScans({
    companyId: COMPANY_ID,
    credits: 1,
    referenceType: "TEST_SCAN",
    referenceId: "test-scan-001",
    idempotencyKey: "wallet-test-consumption-001",
    description: "First test scan",
  });

  console.log("Already processed:", consumption1.alreadyProcessed);
  console.log("Balance:", consumption1.wallet.balance);
  console.log("Consumed:", consumption1.transaction.credits);

  console.log("\n[4] Repeating same consumption with SAME idempotency key...");
  const consumptionDuplicate = await scanWalletService.consumeScans({
    companyId: COMPANY_ID,
    credits: 1,
    referenceType: "TEST_SCAN",
    referenceId: "test-scan-001",
    idempotencyKey: "wallet-test-consumption-001",
    description: "Duplicate test scan",
  });

  console.log("Already processed:", consumptionDuplicate.alreadyProcessed);
  console.log("Balance:", consumptionDuplicate.wallet.balance);
  console.log("Transaction ID:", consumptionDuplicate.transaction.id);

  console.log("\n[5] Consuming remaining 99 scans...");
  const consumption99 = await scanWalletService.consumeScans({
    companyId: COMPANY_ID,
    credits: 99,
    referenceType: "TEST_SCAN",
    referenceId: "test-scan-remaining",
    idempotencyKey: "wallet-test-consumption-002",
    description: "Consume remaining test scans",
  });

  console.log("Already processed:", consumption99.alreadyProcessed);
  console.log("Balance:", consumption99.wallet.balance);
  console.log("Consumed:", consumption99.transaction.credits);

  console.log("\n[6] Attempting consumption with ZERO balance...");
  try {
    await scanWalletService.consumeScans({
      companyId: COMPANY_ID,
      credits: 1,
      referenceType: "TEST_SCAN",
      referenceId: "test-scan-blocked",
      idempotencyKey: "wallet-test-consumption-003",
      description: "Should fail",
    });

    console.log("ERROR: Zero-balance consumption was NOT blocked.");
  } catch (error) {
    console.log("Expected rejection:");
    console.log(error instanceof Error ? error.message : error);
  }

  console.log("\n[7] Final wallet...");
  const finalWallet = await scanWalletService.getWallet(COMPANY_ID);
  console.table(finalWallet);

  console.log("\n[8] Transaction history...");
  const transactions = await scanWalletService.getTransactions(
    COMPANY_ID,
    20,
  );

  console.table(
    transactions.map((transaction) => ({
      id: transaction.id,
      type: transaction.type,
      credits: transaction.credits,
      balanceAfter: transaction.balanceAfter,
      idempotencyKey: transaction.idempotencyKey,
      referenceType: transaction.referenceType,
      referenceId: transaction.referenceId,
    })),
  );

  console.log("\n[9] Cleaning up test data...");

  await prisma.$executeRawUnsafe(
    `
    DELETE FROM scan_transactions
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  await prisma.$executeRawUnsafe(
    `
    DELETE FROM scan_wallets
    WHERE "companyId" = $1
    `,
    COMPANY_ID,
  );

  console.log("Cleanup complete.");

  console.log("\n========================================");
  console.log(" SCAN WALLET TEST COMPLETE");
  console.log("========================================");
}

main()
  .catch((error) => {
    console.error("\nSCAN WALLET TEST FAILED");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
