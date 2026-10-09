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

async function main() {
  console.log("");
  console.log("============================================================");
  console.log(" LOSS DEFENDER - PHASE 5 + 6 INTEGRATION TEST");
  console.log("============================================================");

  const company = await prisma.company.findFirst({
    where: {
      isActive: true,
    },
    orderBy: {
      createdAt: "asc",
    },
  });

  assert(company, "No active company exists.");

  const warehouse = await prisma.warehouse.findFirst({
    where: {
      companyId: company.id,
      isActive: true,
    },
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

  console.log("");
  console.log("[1/8] CSV parsing + mapping");

  const csvValidation = orderImportService.parse(csvBuffer, csvName);

  assert(csvValidation.headers.length >= 5, "CSV headers not detected.");
  assert(csvValidation.mapping.orderId, "Order ID mapping failed.");
  assert(csvValidation.mapping.awb, "AWB mapping failed.");
  assert(csvValidation.mapping.sku, "SKU mapping failed.");
  assert(csvValidation.mapping.productName, "Product Name mapping failed.");
  assert(csvValidation.mapping.quantity, "Quantity mapping failed.");

  console.log("[PASS] CSV mapping.");

  console.log("");
  console.log("[2/8] CSV validation + duplicate detection");

  assert(
    csvValidation.duplicates.length === 1,
    "Expected exactly one duplicate CSV row.",
  );

  assert(csvValidation.valid === true, "CSV should be structurally valid.");

  console.log("[PASS] Duplicate detection.");

  console.log("");
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

  assert(csvImport.createdOrders === 2, "CSV should create two unique orders.");

  assert(csvImport.createdShipments === 1, "CSV should create one shipment.");

  console.log(`[PASS] CSV import: ${csvImport.importedRows} rows.`);

  console.log("");
  console.log("[4/8] XLSX parsing + mapping");

  const xlsxValidation = orderImportService.parse(xlsxBuffer, xlsxName);

  assert(xlsxValidation.valid === true, "XLSX should be structurally valid.");

  assert(xlsxValidation.rows.length === 1, "XLSX should contain one data row.");

  console.log("[PASS] XLSX parsing.");

  console.log("");
  console.log("[5/8] XLSX import");

  const xlsxImport = await orderImportService.import(
    company.id,
    warehouse.id,
    xlsxValidation,
  );

  assert(xlsxImport.importedRows === 1, "XLSX should import one row.");

  console.log("[PASS] XLSX import.");

  console.log("");
  console.log("[6/8] Real AWB lookup");

  const debugAwb = `LD-AWB-CSV-${testSuffix}`;
  const debugShipment = await prisma.shipment.findUnique({
    where: { awb: debugAwb },
  });

  if (debugShipment) {
    const debugOrder = await prisma.order.findUnique({
      where: { id: debugShipment.orderId },
    });
  }

  const awbResult = await scanService.lookup(
    company.id,
    `LD-AWB-CSV-${testSuffix}`,
  );


  assert(awbResult.found === true, "AWB lookup failed.");

  assert(awbResult.lookupType === "AWB", "AWB lookup type is incorrect.");

  assert(Boolean(awbResult.order), "AWB lookup did not return order.");

  assert(Boolean(awbResult.shipment), "AWB lookup did not return shipment.");

  console.log("[PASS] AWB → Shipment → Order lookup.");

  console.log("");
  console.log("[7/8] Real SKU lookup");

  const skuResult = await scanService.lookup(
    company.id,
    `LD-XLSX-SKU-${testSuffix}`,
  );

  assert(skuResult.found === true, "SKU lookup failed.");

  assert(skuResult.lookupType === "SKU", "SKU lookup type is incorrect.");

  console.log("[PASS] SKU → Order → Product lookup.");

  console.log("");
  console.log("[8/8] Invalid barcode protection");

  const invalidResult = await scanService.lookup(
    company.id,
    `INVALID-${testSuffix}`,
  );

  assert(invalidResult.found === false, "Invalid barcode must not resolve.");

  console.log("[PASS] Invalid barcode correctly rejected.");

  const orderCount = await prisma.order.count({
    where: {
      companyId: company.id,
      OR: [
        {
          externalOrderId: `LD-CSV-${testSuffix}`,
        },
        {
          externalOrderId: `LD-XLSX-${testSuffix}`,
        },
      ],
    },
  });

  const shipmentCount = await prisma.shipment.count({
    where: {
      awb: {
        in: [`LD-AWB-CSV-${testSuffix}`, `LD-AWB-XLSX-${testSuffix}`],
      },
    },
  });

  const productCount = await prisma.product.count({
    where: {
      companyId: company.id,
      sku: {
        in: [
          `LD-CSV-SKU-${testSuffix}`,
          `LD-CSV-SKU-2-${testSuffix}`,
          `LD-XLSX-SKU-${testSuffix}`,
        ],
      },
    },
  });

  assert(orderCount === 3, `Expected 3 test orders, found ${orderCount}.`);

  assert(
    shipmentCount === 2,
    `Expected 2 test shipments, found ${shipmentCount}.`,
  );

  assert(
    productCount === 3,
    `Expected 3 test products, found ${productCount}.`,
  );

  console.log("");
  console.log("============================================================");
  console.log(" ALL PHASE 5 + PHASE 6 TESTS PASSED");
  console.log("============================================================");
  console.log("");
  console.log(`Company:       ${company.name}`);
  console.log(`Warehouse:     ${warehouse.name}`);
  console.log(`Orders tested: 3 (2 CSV + 1 XLSX)`);
  console.log(`Shipments:     2`);
  console.log(`Products:      3`);
  console.log(`CSV:           PASS`);
  console.log(`XLSX:          PASS`);
  console.log(`Mapping:       PASS`);
  console.log(`Validation:    PASS`);
  console.log(`Duplicates:    PASS`);
  console.log(`Import:        PASS`);
  console.log(`AWB Lookup:    PASS`);
  console.log(`SKU Lookup:    PASS`);
  console.log(`Invalid Scan:  PASS`);
  console.log("");

  await prisma.$disconnect();
}

main().catch(async (error) => {
  console.error("");
  console.error("============================================================");
  console.error(" PHASE 5 + 6 TEST FAILED");
  console.error("============================================================");
  console.error(error);
  console.error("");

  await prisma.$disconnect();
  process.exit(1);
});







