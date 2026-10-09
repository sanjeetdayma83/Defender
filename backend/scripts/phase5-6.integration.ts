import "dotenv/config";

import * as XLSX from "xlsx";

import { prisma } from "../src/config/prisma.js";
import { orderImportService } from "../src/services/imports/order-import.service.js";
import { scanService } from "../src/services/scan/scan.service.js";

function assert(condition: unknown, message: string): void {
  if (!condition) {
    throw new Error(`TEST FAILED: ${message}`);
  }
}

function isWriteMode(): boolean {
  return process.env.LD_TEST_MODE === "write";
}

async function readOnlySchemaSmokeTest(): Promise<void> {
  console.log("");
  console.log("[READ-ONLY] Database/schema smoke test");

  const requiredTables = [
    "companies",
    "users",
    "warehouses",
    "products",
    "product_variants",
    "barcode_aliases",
    "orders",
    "order_items",
    "shipments",
    "shipment_barcodes",
    "packing_sessions",
    "evidence_media",
    "plans",
    "subscriptions",
    "scan_wallets",
    "scan_transactions",
    "audit_logs",
    "storage_objects",
    "storage_usage_events",
    "billing_profiles",
    "invoices",
    "invoice_items",
  ];

  const rows = await prisma.$queryRaw<
    Array<{ table_name: string }>
  >`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = ANY(${requiredTables})
    ORDER BY table_name
  `;

  const existing = new Set(rows.map((row) => row.table_name));

  for (const table of requiredTables) {
    assert(
      existing.has(table),
      `Required table missing: ${table}`,
    );
  }

  console.log(
    `[PASS] ${requiredTables.length} required application tables exist.`,
  );

  const companyCount = await prisma.company.count();

  console.log(`[INFO] Companies currently present: ${companyCount}`);

  if (companyCount > 0) {
    const company = await prisma.company.findFirst({
      where: { status: "active" },
      orderBy: {
        createdAt: "asc",
      },
    });

    if (company) {
      const invalidResult = await scanService.lookup(
        company.id,
        `LD-INVALID-SMOKE-${Date.now()}`,
      );

      assert(
        invalidResult.found === false,
        "Invalid barcode unexpectedly resolved.",
      );

      console.log("[PASS] Invalid barcode protection.");
    }
  }

  console.log("[PASS] Read-only database smoke test.");
}

async function writeIntegrationTest(): Promise<void> {
  console.log("");
  console.log("[WRITE] Phase 5/6 integration test");

  const company = await prisma.company.findFirst({
    where: { status: "active" },
    orderBy: {
      createdAt: "asc",
    },
  });

  assert(company, "No active company exists.");

  const warehouse = await prisma.warehouse.findFirst({
    where: { companyId: company.id, status: "active" },
    orderBy: {
      createdAt: "asc",
    },
  });

  assert(warehouse, "No active warehouse exists.");

  const testSuffix = Date.now();

  const csvName = `phase5-test-${testSuffix}.csv`;
  const xlsxName = `phase5-test-${testSuffix}.xlsx`;

  const csvContent = [
    "Order ID,AWB,SKU,Product Name,Quantity,Variant,Color,Size,Marketplace,Customer Name,Image URL",
    `LD-CSV-${testSuffix},LD-AWB-CSV-${testSuffix},LD-CSV-SKU-${testSuffix},CSV Test Product,2,Standard,Blue,Large,Other,CSV Customer,`,
    `LD-CSV-${testSuffix},LD-AWB-CSV-${testSuffix},LD-CSV-SKU-2-${testSuffix},CSV Second Product,1,,Red,Medium,Amazon,CSV Customer,`,
    `LD-CSV-${testSuffix},LD-AWB-CSV-${testSuffix},LD-CSV-SKU-${testSuffix},CSV Test Product,2,Standard,Blue,Large,Other,CSV Customer,`,
  ].join("\n");

  const xlsxRows = [
    [
      "Order ID",
      "AWB",
      "SKU",
      "Product Name",
      "Quantity",
      "Variant",
      "Color",
      "Size",
      "Marketplace",
      "Customer Name",
    ],
    [
      `LD-XLSX-${testSuffix}`,
      `LD-AWB-XLSX-${testSuffix}`,
      `LD-XLSX-SKU-${testSuffix}`,
      "XLSX Test Product",
      3,
      "Premium",
      "Green",
      "XL",
      "Flipkart",
      "XLSX Customer",
    ],
  ];

  const workbook = XLSX.utils.book_new();
  const worksheet = XLSX.utils.aoa_to_sheet(xlsxRows);

  XLSX.utils.book_append_sheet(workbook, worksheet, "Orders");

  const xlsxBuffer = XLSX.write(workbook, {
    type: "buffer",
    bookType: "xlsx",
  });

  const csvBuffer = Buffer.from(csvContent, "utf8");

  console.log("[1/8] CSV parsing + mapping");

  const csvValidation = orderImportService.parse(csvBuffer, csvName);

  assert(csvValidation.headers.length >= 5, "CSV headers not detected.");
  assert(csvValidation.mapping.orderId, "Order ID mapping failed.");
  assert(csvValidation.mapping.awb, "AWB mapping failed.");
  assert(csvValidation.mapping.sku, "SKU mapping failed.");
  assert(csvValidation.mapping.productName, "Product Name mapping failed.");
  assert(csvValidation.mapping.quantity, "Quantity mapping failed.");

  console.log("[PASS] CSV mapping.");

  console.log("[2/8] CSV validation + duplicate detection");

  assert(
    csvValidation.duplicates.length === 1,
    "Expected exactly one duplicate CSV row.",
  );

  assert(
    csvValidation.valid === true,
    "CSV should be structurally valid.",
  );

  console.log("[PASS] Duplicate detection.");

  console.log("[3/8] CSV import");

  const csvImport = await orderImportService.import(
    company.id,
    warehouse.id,
    csvValidation,
  );

  assert(
    csvImport.importedRows === 2,
    "CSV should import exactly two unique rows.",
  );

  assert(
    csvImport.createdOrders === 2,
    "CSV should create two unique orders.",
  );

  assert(
    csvImport.createdShipments === 1,
    "CSV should create one shipment.",
  );

  console.log("[PASS] CSV import.");

  console.log("[4/8] XLSX parsing + mapping");

  const xlsxValidation = orderImportService.parse(
    xlsxBuffer,
    xlsxName,
  );

  assert(
    xlsxValidation.valid === true,
    "XLSX should be structurally valid.",
  );

  assert(
    xlsxValidation.rows.length === 1,
    "XLSX should contain one data row.",
  );

  console.log("[PASS] XLSX parsing.");

  console.log("[5/8] XLSX import");

  const xlsxImport = await orderImportService.import(
    company.id,
    warehouse.id,
    xlsxValidation,
  );

  assert(
    xlsxImport.importedRows === 1,
    "XLSX should import one row.",
  );

  console.log("[PASS] XLSX import.");

  console.log("[6/8] AWB lookup");

  const awbResult = await scanService.lookup(
    company.id,
    `LD-AWB-CSV-${testSuffix}`,
  );

  assert(
    awbResult.found === true,
    "AWB lookup failed.",
  );

  assert(
    awbResult.lookupType === "AWB",
    "AWB lookup type is incorrect.",
  );

  assert(
    Boolean(awbResult.order),
    "AWB lookup did not return order.",
  );

  assert(
    Boolean(awbResult.shipment),
    "AWB lookup did not return shipment.",
  );

  console.log("[PASS] AWB -> Shipment -> Order lookup.");

  console.log("[7/8] SKU lookup");

  const skuResult = await scanService.lookup(
    company.id,
    `LD-XLSX-SKU-${testSuffix}`,
  );

  assert(
    skuResult.found === true,
    "SKU lookup failed.",
  );

  assert(
    skuResult.lookupType === "SKU",
    "SKU lookup type is incorrect.",
  );

  console.log("[PASS] SKU lookup.");

  console.log("[8/8] Invalid barcode protection");

  const invalidResult = await scanService.lookup(
    company.id,
    `INVALID-${testSuffix}`,
  );

  assert(
    invalidResult.found === false,
    "Invalid barcode must not resolve.",
  );

  console.log("[PASS] Invalid barcode protection.");

  console.log("");
  console.log("WRITE INTEGRATION TEST PASSED.");
  console.log(
    "NOTE: test rows remain in the database and must only be run against a disposable/staging database.",
  );
}

async function main(): Promise<void> {
  console.log("");
  console.log("============================================================");
  console.log(" LOSS DEFENDER - PHASE 5 + 6 INTEGRATION TEST");
  console.log("============================================================");

  if (isWriteMode()) {
    await writeIntegrationTest();
  } else {
    console.log("");
    console.log("MODE: READ-ONLY");
    console.log(
      "Set LD_TEST_MODE=write only on a disposable/staging database to execute import writes.",
    );

    await readOnlySchemaSmokeTest();
  }

  console.log("");
  console.log("============================================================");
  console.log(" PHASE 5 + 6 TEST PASSED");
  console.log("============================================================");
}

main()
  .catch((error) => {
    console.error("");
    console.error("============================================================");
    console.error(" PHASE 5 + 6 TEST FAILED");
    console.error("============================================================");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


