import "dotenv/config";

import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../src/generated/prisma/client.js";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL is not configured.");
}

const adapter = new PrismaPg({
  connectionString,
});

const prisma = new PrismaClient({
  adapter,
});

async function main() {
  console.log("Starting Loss Defender database seed...");

  // ----------------------------------------------------------
  // COMPANY
  // ----------------------------------------------------------

  const company = await prisma.company.upsert({
    where: {
      code: "LOSS-DEFENDER-DEMO",
    },
    update: {
      name: "Loss Defender Demo",
      isActive: true,
    },
    create: {
      name: "Loss Defender Demo",
      code: "LOSS-DEFENDER-DEMO",
      isActive: true,
    },
  });

  console.log(`Company: ${company.name}`);

  // ----------------------------------------------------------
  // WAREHOUSE
  // ----------------------------------------------------------

  const warehouse = await prisma.warehouse.upsert({
    where: {
      companyId_code: {
        companyId: company.id,
        code: "MAIN",
      },
    },
    update: {
      name: "Main Warehouse",
      isActive: true,
    },
    create: {
      name: "Main Warehouse",
      code: "MAIN",
      country: "India",
      companyId: company.id,
      isActive: true,
    },
  });

  console.log(`Warehouse: ${warehouse.name}`);

  // ----------------------------------------------------------
  // MARKETPLACE ACCOUNTS
  // ----------------------------------------------------------

  const amazonAccount = await prisma.marketplaceAccount.upsert({
    where: {
      companyId_marketplace_accountName: {
        companyId: company.id,
        marketplace: "AMAZON",
        accountName: "Amazon Demo",
      },
    },
    update: {
      isActive: true,
    },
    create: {
      companyId: company.id,
      marketplace: "AMAZON",
      accountName: "Amazon Demo",
      isActive: true,
    },
  });

  const flipkartAccount = await prisma.marketplaceAccount.upsert({
    where: {
      companyId_marketplace_accountName: {
        companyId: company.id,
        marketplace: "FLIPKART",
        accountName: "Flipkart Demo",
      },
    },
    update: {
      isActive: true,
    },
    create: {
      companyId: company.id,
      marketplace: "FLIPKART",
      accountName: "Flipkart Demo",
      isActive: true,
    },
  });

  const otherAccount = await prisma.marketplaceAccount.upsert({
    where: {
      companyId_marketplace_accountName: {
        companyId: company.id,
        marketplace: "OTHER",
        accountName: "Other Demo",
      },
    },
    update: {
      isActive: true,
    },
    create: {
      companyId: company.id,
      marketplace: "OTHER",
      accountName: "Other Demo",
      isActive: true,
    },
  });

  console.log("Marketplace accounts created.");

  // ----------------------------------------------------------
  // PRODUCT 1
  // ----------------------------------------------------------

  const product1 = await prisma.product.upsert({
    where: {
      companyId_sku: {
        companyId: company.id,
        sku: "97-U1YR-N3GW",
      },
    },
    update: {
      name: "Demo Product - 97-U1YR-N3GW",
      isActive: true,
    },
    create: {
      companyId: company.id,
      sku: "97-U1YR-N3GW",
      name: "Demo Product - 97-U1YR-N3GW",
      isActive: true,
    },
  });

  const variant1 = await prisma.productVariant.upsert({
    where: {
      productId_sku: {
        productId: product1.id,
        sku: "97-U1YR-N3GW",
      },
    },
    update: {
      variantName: "Default",
      isActive: true,
    },
    create: {
      productId: product1.id,
      sku: "97-U1YR-N3GW",
      variantName: "Default",
      quantity: 100,
      isActive: true,
    },
  });

  await prisma.barcodeAlias.upsert({
    where: {
      barcode: "97-U1YR-N3GW",
    },
    update: {
      productId: product1.id,
      variantId: variant1.id,
      type: "SKU",
      isActive: true,
    },
    create: {
      barcode: "97-U1YR-N3GW",
      type: "SKU",
      productId: product1.id,
      variantId: variant1.id,
      isActive: true,
    },
  });

  // ----------------------------------------------------------
  // PRODUCT 2
  // ----------------------------------------------------------

  const product2 = await prisma.product.upsert({
    where: {
      companyId_sku: {
        companyId: company.id,
        sku: "PC-TWISTER-001",
      },
    },
    update: {
      name: "PC Twister Demo",
      isActive: true,
    },
    create: {
      companyId: company.id,
      sku: "PC-TWISTER-001",
      name: "PC Twister Demo",
      isActive: true,
    },
  });

  const variant2 = await prisma.productVariant.upsert({
    where: {
      productId_sku: {
        productId: product2.id,
        sku: "PC-TWISTER-001",
      },
    },
    update: {
      variantName: "Blue",
      color: "Blue",
      isActive: true,
    },
    create: {
      productId: product2.id,
      sku: "PC-TWISTER-001",
      variantName: "Blue",
      color: "Blue",
      quantity: 100,
      isActive: true,
    },
  });

  await prisma.barcodeAlias.upsert({
    where: {
      barcode: "PC-TWISTER-001",
    },
    update: {
      productId: product2.id,
      variantId: variant2.id,
      type: "SKU",
      isActive: true,
    },
    create: {
      barcode: "PC-TWISTER-001",
      type: "SKU",
      productId: product2.id,
      variantId: variant2.id,
      isActive: true,
    },
  });

  // ----------------------------------------------------------
  // PRODUCT 3
  // ----------------------------------------------------------

  const product3 = await prisma.product.upsert({
    where: {
      companyId_sku: {
        companyId: company.id,
        sku: "DG-LT-S",
      },
    },
    update: {
      name: "NOVELTY Foldable Height Adjustable White Board",
      isActive: true,
    },
    create: {
      companyId: company.id,
      sku: "DG-LT-S",
      name: "NOVELTY Foldable Height Adjustable White Board",
      isActive: true,
    },
  });

  const variant3 = await prisma.productVariant.upsert({
    where: {
      productId_sku: {
        productId: product3.id,
        sku: "DG-LT-S",
      },
    },
    update: {
      variantName: "Default",
      isActive: true,
    },
    create: {
      productId: product3.id,
      sku: "DG-LT-S",
      variantName: "Default",
      quantity: 100,
      isActive: true,
    },
  });

  await prisma.barcodeAlias.upsert({
    where: {
      barcode: "DG-LT-S",
    },
    update: {
      productId: product3.id,
      variantId: variant3.id,
      type: "SKU",
      isActive: true,
    },
    create: {
      barcode: "DG-LT-S",
      type: "SKU",
      productId: product3.id,
      variantId: variant3.id,
      isActive: true,
    },
  });

  console.log("Products and SKU barcodes created.");

  // ----------------------------------------------------------
  // ORDER 1 - AMAZON
  // ----------------------------------------------------------

  const order1 = await prisma.order.upsert({
    where: {
      companyId_marketplace_externalOrderId: {
        companyId: company.id,
        marketplace: "AMAZON",
        externalOrderId: "406-3151945-3281902",
      },
    },
    update: {
      status: "PENDING",
      warehouseId: warehouse.id,
      marketplaceAccountId: amazonAccount.id,
    },
    create: {
      externalOrderId: "406-3151945-3281902",
      marketplaceOrderId: "406-3151945-3281902",
      marketplace: "AMAZON",
      status: "PENDING",
      companyId: company.id,
      warehouseId: warehouse.id,
      marketplaceAccountId: amazonAccount.id,
    },
  });

  const order1Item = await prisma.orderItem.findFirst({
    where: {
      orderId: order1.id,
      productId: product1.id,
    },
  });

  if (!order1Item) {
    await prisma.orderItem.create({
      data: {
        orderId: order1.id,
        productId: product1.id,
        variantId: variant1.id,
        quantity: 1,
      },
    });
  }

  const shipment1 = await prisma.shipment.upsert({
    where: {
      awb: "368275770371",
    },
    update: {
      orderId: order1.id,
      carrier: "Amazon",
      status: "READY_TO_PACK",
    },
    create: {
      awb: "368275770371",
      carrier: "Amazon",
      status: "READY_TO_PACK",
      orderId: order1.id,
    },
  });

  await prisma.shipmentBarcode.upsert({
    where: {
      barcode: "368275770371",
    },
    update: {
      shipmentId: shipment1.id,
      type: "AWB",
      isActive: true,
    },
    create: {
      barcode: "368275770371",
      shipmentId: shipment1.id,
      type: "AWB",
      isActive: true,
    },
  });

  // ----------------------------------------------------------
  // ORDER 2 - OTHER / DELHIVERY
  // ----------------------------------------------------------

  const order2 = await prisma.order.upsert({
    where: {
      companyId_marketplace_externalOrderId: {
        companyId: company.id,
        marketplace: "OTHER",
        externalOrderId: "331724360573683072_1",
      },
    },
    update: {
      status: "PENDING",
      warehouseId: warehouse.id,
      marketplaceAccountId: otherAccount.id,
    },
    create: {
      externalOrderId: "331724360573683072_1",
      marketplaceOrderId: "331724360573683072_1",
      marketplace: "OTHER",
      status: "PENDING",
      companyId: company.id,
      warehouseId: warehouse.id,
      marketplaceAccountId: otherAccount.id,
    },
  });

  const order2Item = await prisma.orderItem.findFirst({
    where: {
      orderId: order2.id,
      productId: product2.id,
    },
  });

  if (!order2Item) {
    await prisma.orderItem.create({
      data: {
        orderId: order2.id,
        productId: product2.id,
        variantId: variant2.id,
        quantity: 1,
      },
    });
  }

  const shipment2 = await prisma.shipment.upsert({
    where: {
      awb: "1490841263428112",
    },
    update: {
      orderId: order2.id,
      carrier: "Delhivery",
      status: "READY_TO_PACK",
    },
    create: {
      awb: "1490841263428112",
      carrier: "Delhivery",
      status: "READY_TO_PACK",
      orderId: order2.id,
    },
  });

  await prisma.shipmentBarcode.upsert({
    where: {
      barcode: "1490841263428112",
    },
    update: {
      shipmentId: shipment2.id,
      type: "AWB",
      isActive: true,
    },
    create: {
      barcode: "1490841263428112",
      shipmentId: shipment2.id,
      type: "AWB",
      isActive: true,
    },
  });

  // ----------------------------------------------------------
  // ORDER 3 - FLIPKART
  // ----------------------------------------------------------

  const order3 = await prisma.order.upsert({
    where: {
      companyId_marketplace_externalOrderId: {
        companyId: company.id,
        marketplace: "FLIPKART",
        externalOrderId: "FK-3767030215",
      },
    },
    update: {
      status: "PACKED",
      warehouseId: warehouse.id,
      marketplaceAccountId: flipkartAccount.id,
    },
    create: {
      externalOrderId: "FK-3767030215",
      marketplaceOrderId: "331724360573683072_1",
      marketplace: "FLIPKART",
      status: "PACKED",
      companyId: company.id,
      warehouseId: warehouse.id,
      marketplaceAccountId: flipkartAccount.id,
    },
  });

  const order3Item = await prisma.orderItem.findFirst({
    where: {
      orderId: order3.id,
      productId: product3.id,
    },
  });

  if (!order3Item) {
    await prisma.orderItem.create({
      data: {
        orderId: order3.id,
        productId: product3.id,
        variantId: variant3.id,
        quantity: 1,
      },
    });
  }

  const shipment3 = await prisma.shipment.upsert({
    where: {
      awb: "FMPP3767030215",
    },
    update: {
      orderId: order3.id,
      carrier: "Flipkart",
      status: "PACKED",
    },
    create: {
      awb: "FMPP3767030215",
      carrier: "Flipkart",
      status: "PACKED",
      orderId: order3.id,
    },
  });

  await prisma.shipmentBarcode.upsert({
    where: {
      barcode: "FMPP3767030215",
    },
    update: {
      shipmentId: shipment3.id,
      type: "AWB",
      isActive: true,
    },
    create: {
      barcode: "FMPP3767030215",
      shipmentId: shipment3.id,
      type: "AWB",
      isActive: true,
    },
  });

  console.log("Orders and shipments created.");

  console.log("");
  console.log("============================================");
  console.log(" LOSS DEFENDER SEED COMPLETE");
  console.log("============================================");
  console.log(`Company ID:   ${company.id}`);
  console.log(`Warehouse ID: ${warehouse.id}`);
  console.log(`Products:     3`);
  console.log(`Orders:       3`);
  console.log(`Shipments:    3`);
}

main()
  .catch((error) => {
    console.error("");
    console.error("SEED FAILED");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
