import * as XLSX from "xlsx";

import { prisma } from "../../config/prisma.js";
import {
  Marketplace,
  OrderStatus,
  ShipmentStatus,
} from "../../generated/prisma/enums.js";

export interface ImportMapping {
  orderId: string;
  awb: string;
  sku: string;
  productName: string;
  quantity: string;
  variant?: string;
  color?: string;
  size?: string;
  marketplace?: string;
  customerName?: string;
  imageUrl?: string;
  orderDate?: string;
}

export interface NormalizedImportRow {
  rowNumber: number;
  orderId: string;
  awb: string;
  sku: string;
  productName: string;
  quantity: number;
  variant?: string;
  color?: string;
  size?: string;
  marketplace: Marketplace;
  customerName?: string;
  imageUrl?: string;
  orderDate?: Date;
}

export interface ImportIssue {
  rowNumber: number;
  field?: string;
  message: string;
}

export interface ImportValidationResult {
  headers: string[];
  mapping: ImportMapping;
  rows: NormalizedImportRow[];
  issues: ImportIssue[];
  duplicates: ImportIssue[];
  valid: boolean;
}

export interface ImportResult {
  totalRows: number;
  importedRows: number;
  createdProducts: number;
  updatedProducts: number;
  createdVariants: number;
  updatedVariants: number;
  createdOrders: number;
  updatedOrders: number;
  createdShipments: number;
  updatedShipments: number;
  createdOrderItems: number;
  updatedOrderItems: number;
  duplicateRows: number;
  errorRows: number;
  issues: ImportIssue[];
}

type RawRow = Record<string, unknown>;

const FIELD_ALIASES: Record<keyof ImportMapping, string[]> = {
  orderId: [
    "order id",
    "orderid",
    "order",
    "order no",
    "order number",
    "external order id",
    "externalorderid",
  ],
  awb: [
    "awb",
    "awb no",
    "awb number",
    "shipping barcode",
    "shipping barcode no",
    "shipment barcode",
    "tracking number",
    "tracking id",
    "waybill",
  ],
  sku: ["sku", "product sku", "seller sku", "item sku", "seller sku id"],
  productName: [
    "product name",
    "product",
    "item name",
    "product title",
    "description",
  ],
  quantity: ["quantity", "qty", "item quantity", "order quantity"],
  variant: ["variant", "variant name", "variantname"],
  color: ["color", "colour"],
  size: ["size"],
  marketplace: ["marketplace", "channel", "platform", "source"],
  customerName: ["customer name", "customer", "buyer name"],
  imageUrl: ["image url", "image", "product image", "image link"],
  orderDate: ["order date", "ordered at", "order datetime", "order time"],
};

const REQUIRED_FIELDS: Array<keyof ImportMapping> = [
  "orderId",
  "awb",
  "sku",
  "productName",
  "quantity",
];

function clean(value: unknown): string {
  return String(value ?? "").trim();
}

function expandScientificNotation(value: string): string {
  const match = value.match(
    /^([+-]?)(\d+)(?:\.(\d*))?[eE]([+-]?\d+)$/,
  );

  if (!match) {
    return value;
  }

  const sign = match[1] ?? "";
  const integerPart = match[2] ?? "";
  const fractionalPart = match[3] ?? "";
  const exponent = Number(match[4]);

  if (!Number.isInteger(exponent)) {
    return value;
  }

  const digits = `${integerPart}${fractionalPart}`;
  const decimalPosition = integerPart.length + exponent;

  let expanded: string;

  if (decimalPosition <= 0) {
    expanded = `0.${"0".repeat(Math.abs(decimalPosition))}${digits}`;
  } else if (decimalPosition >= digits.length) {
    expanded = `${digits}${"0".repeat(decimalPosition - digits.length)}`;
  } else {
    expanded =
      `${digits.slice(0, decimalPosition)}.${digits.slice(decimalPosition)}`;
  }

  if (expanded.includes(".")) {
    expanded = expanded.replace(/\.0+$/, "");
  }

  return `${sign}${expanded}`;
}

function normalizeAwb(value: unknown): string {
  const raw = clean(value);

  if (!raw) {
    return "";
  }

  if (/^[+-]?(?:\d+(?:\.\d+)?|\.\d+)[eE][+-]?\d+$/.test(raw)) {
    return expandScientificNotation(raw);
  }

  if (/^\d+\.0+$/.test(raw)) {
    return raw.split(".")[0];
  }

  return raw;
}

function normalizeHeader(value: string): string {
  return value
    .toLowerCase()
    .trim()
    .replace(/[\r\n]+/g, " ")
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ");
}

function marketplaceFromValue(value: string): Marketplace {
  const normalized = normalizeHeader(value);

  if (normalized.includes("amazon")) return Marketplace.AMAZON;
  if (normalized.includes("flipkart")) return Marketplace.FLIPKART;
  if (normalized.includes("meesho")) return Marketplace.MEESHO;

  return Marketplace.OTHER;
}

function parseDate(value: string): Date | undefined {
  if (!value) return undefined;

  const date = new Date(value);

  if (!Number.isNaN(date.getTime())) {
    return date;
  }

  const excelNumber = Number(value);

  if (Number.isFinite(excelNumber) && excelNumber > 20000) {
    const parsed = XLSX.SSF.parse_date_code(excelNumber);

    if (parsed) {
      return new Date(
        parsed.y,
        parsed.m - 1,
        parsed.d,
        parsed.H,
        parsed.M,
        parsed.S,
      );
    }
  }

  return undefined;
}

function inferMapping(headers: string[]): ImportMapping {
  const normalizedHeaders = new Map<string, string>();

  for (const header of headers) {
    normalizedHeaders.set(normalizeHeader(header), header);
  }

  const result: Partial<ImportMapping> = {};

  for (const field of Object.keys(FIELD_ALIASES) as Array<
    keyof ImportMapping
  >) {
    const aliases = FIELD_ALIASES[field];

    for (const alias of aliases) {
      const exact = normalizedHeaders.get(normalizeHeader(alias));

      if (exact) {
        result[field] = exact;
        break;
      }
    }
  }

  return result as ImportMapping;
}

function applyMapping(
  row: RawRow,
  mapping: ImportMapping,
  rowNumber: number,
): {
  row?: NormalizedImportRow;
  issues: ImportIssue[];
} {
  const issues: ImportIssue[] = [];

  const valueFor = (field: keyof ImportMapping): string => {
    const source = mapping[field];
    if (!source) return "";
    return clean(row[source]);
  };

  const orderId = valueFor("orderId");
  const awb = normalizeAwb(valueFor("awb"));
  const sku = valueFor("sku");
  const productName = valueFor("productName");
  const quantityText = valueFor("quantity");

  if (!orderId) {
    issues.push({
      rowNumber,
      field: "orderId",
      message: "Order ID is required.",
    });
  }

  if (!awb) {
    issues.push({
      rowNumber,
      field: "awb",
      message: "AWB / Shipping Barcode is required.",
    });
  }

  if (!sku) {
    issues.push({
      rowNumber,
      field: "sku",
      message: "SKU is required.",
    });
  }

  if (!productName) {
    issues.push({
      rowNumber,
      field: "productName",
      message: "Product Name is required.",
    });
  }

  const quantity = Number(quantityText);

  if (!Number.isInteger(quantity) || quantity <= 0) {
    issues.push({
      rowNumber,
      field: "quantity",
      message: "Quantity must be a positive integer.",
    });
  }

  const marketplaceText = valueFor("marketplace");

  const normalized: NormalizedImportRow = {
    rowNumber,
    orderId,
    awb,
    sku,
    productName,
    quantity,
    variant: valueFor("variant") || undefined,
    color: valueFor("color") || undefined,
    size: valueFor("size") || undefined,
    marketplace: marketplaceFromValue(marketplaceText),
    customerName: valueFor("customerName") || undefined,
    imageUrl: valueFor("imageUrl") || undefined,
    orderDate: parseDate(valueFor("orderDate")),
  };

  if (issues.length > 0) {
    return {
      issues,
    };
  }

  return {
    row: normalized,
    issues: [],
  };
}

function parseWorkbook(
  buffer: Buffer,
  filename: string,
): {
  headers: string[];
  rows: RawRow[];
} {
  const extension = filename.toLowerCase().split(".").pop();

  if (!["csv", "xlsx", "xls"].includes(extension ?? "")) {
    throw new Error("Only CSV, XLSX and XLS files are supported.");
  }

  const workbook = XLSX.read(buffer, {
    type: "buffer",
    cellDates: false,
    raw: false,
  });

  const firstSheetName = workbook.SheetNames[0];

  if (!firstSheetName) {
    throw new Error("The uploaded file does not contain a worksheet.");
  }

  const sheet = workbook.Sheets[firstSheetName];

  if (!sheet) {
    throw new Error("The first worksheet could not be read.");
  }

  const matrix = XLSX.utils.sheet_to_json<unknown[]>(sheet, {
    header: 1,
    defval: "",
    raw: false,
  });

  if (matrix.length === 0) {
    throw new Error("The uploaded file is empty.");
  }

  const headerRow = matrix[0] ?? [];

  const headers = headerRow.map((value) => clean(value));

  if (headers.every((header) => !header)) {
    throw new Error("The uploaded file does not contain a header row.");
  }

  const rows: RawRow[] = [];

  for (let index = 1; index < matrix.length; index += 1) {
    const values = matrix[index] ?? [];

    const row: RawRow = {};
    let hasValue = false;

    for (let column = 0; column < headers.length; column += 1) {
      const header = headers[column];

      if (!header) continue;

      const value = values[column] ?? "";

      if (clean(value)) {
        hasValue = true;
      }

      row[header] = value;
    }

    if (hasValue) {
      rows.push(row);
    }
  }

  return {
    headers,
    rows,
  };
}

export class OrderImportService {
  parse(buffer: Buffer, filename: string): ImportValidationResult {
    const workbook = parseWorkbook(buffer, filename);
    const mapping = inferMapping(workbook.headers);

    const issues: ImportIssue[] = [];
    const duplicates: ImportIssue[] = [];
    const normalizedRows: NormalizedImportRow[] = [];

    for (const field of REQUIRED_FIELDS) {
      if (!mapping[field]) {
        issues.push({
          rowNumber: 1,
          field,
          message: `Required column could not be mapped: ${field}.`,
        });
      }
    }

    for (let index = 0; index < workbook.rows.length; index += 1) {
      const rowNumber = index + 2;

      const result = applyMapping(workbook.rows[index], mapping, rowNumber);

      issues.push(...result.issues);

      if (result.row) {
        normalizedRows.push(result.row);
      }
    }

    const seen = new Set<string>();

    for (const row of normalizedRows) {
      const key = [
        row.orderId.toLowerCase(),
        row.awb.toLowerCase(),
        row.sku.toLowerCase(),
      ].join("|");

      if (seen.has(key)) {
        duplicates.push({
          rowNumber: row.rowNumber,
          message: `Duplicate row detected for Order ${row.orderId}, AWB ${row.awb}, SKU ${row.sku}.`,
        });
      }

      seen.add(key);
    }

    return {
      headers: workbook.headers,
      mapping,
      rows: normalizedRows,
      issues,
      duplicates,
      valid: issues.length === 0 && normalizedRows.length > 0,
    };
  }

  async import(
    companyId: string,
    warehouseId: string,
    validation: ImportValidationResult,
  ): Promise<ImportResult> {
    if (!validation.valid) {
      throw new Error("IMPORT_VALIDATION_FAILED");
    }

    const issues: ImportIssue[] = [...validation.duplicates];

    const duplicateKeys = new Set(
      validation.duplicates.map((issue) => issue.rowNumber),
    );

    const result: ImportResult = {
      totalRows: validation.rows.length,
      importedRows: 0,
      createdProducts: 0,
      updatedProducts: 0,
      createdVariants: 0,
      updatedVariants: 0,
      createdOrders: 0,
      updatedOrders: 0,
      createdShipments: 0,
      updatedShipments: 0,
      createdOrderItems: 0,
      updatedOrderItems: 0,
      duplicateRows: validation.duplicates.length,
      errorRows: validation.issues.length,
      issues,
    };

    await prisma.$transaction(
      async (tx) => {
      for (const row of validation.rows) {
        if (duplicateKeys.has(row.rowNumber)) {
          continue;
        }

        const existingProduct = await tx.product.findUnique({
          where: {
            companyId_sku: {
              companyId,
              sku: row.sku,
            },
          },
        });

        const product = await tx.product.upsert({
          where: {
            companyId_sku: {
              companyId,
              sku: row.sku,
            },
          },
          update: {
            name: row.productName,
            imageUrl: row.imageUrl,
            isActive: true,
          },
          create: {
            companyId,
            sku: row.sku,
            name: row.productName,
            imageUrl: row.imageUrl,
            isActive: true,
          },
        });

        if (existingProduct) {
          result.updatedProducts += 1;
        } else {
          result.createdProducts += 1;
        }

        let variantId: string | undefined;

        const variantKey = [row.variant, row.color, row.size]
          .filter(Boolean)
          .join("|");

        if (variantKey) {
          const variantSku = `${row.sku}::${variantKey}`;

          const existingVariant = await tx.productVariant.findUnique({
            where: {
              productId_sku: {
                productId: product.id,
                sku: variantSku,
              },
            },
          });

          const variant = await tx.productVariant.upsert({
            where: {
              productId_sku: {
                productId: product.id,
                sku: variantSku,
              },
            },
            update: {
              name: row.variant ?? row.productName,
              variantName: row.variant,
              color: row.color,
              size: row.size,
              imageUrl: row.imageUrl,
              isActive: true,
            },
            create: {
              productId: product.id,
              sku: variantSku,
              name: row.variant ?? row.productName,
              variantName: row.variant,
              color: row.color,
              size: row.size,
              imageUrl: row.imageUrl,
              quantity: 0,
              isActive: true,
            },
          });

          variantId = variant.id;

          if (existingVariant) {
            result.updatedVariants += 1;
          } else {
            result.createdVariants += 1;
          }
        }

        const existingOrder = await tx.order.findUnique({
          where: {
            companyId_marketplace_externalOrderId: {
              companyId,
              marketplace: row.marketplace,
              externalOrderId: row.orderId,
            },
          },
        });

        const order = await tx.order.upsert({
          where: {
            companyId_marketplace_externalOrderId: {
              companyId,
              marketplace: row.marketplace,
              externalOrderId: row.orderId,
            },
          },
          update: {
            warehouseId,
            customerName: row.customerName,
            orderedAt: row.orderDate,
            status: OrderStatus.PENDING,
          },
          create: {
            companyId,
            warehouseId,
            externalOrderId: row.orderId,
            marketplaceOrderId: row.orderId,
            marketplace: row.marketplace,
            customerName: row.customerName,
            orderedAt: row.orderDate,
            status: OrderStatus.PENDING,
          },
        });

        if (existingOrder) {
          result.updatedOrders += 1;
        } else {
          result.createdOrders += 1;
        }

        const existingItem = await tx.orderItem.findFirst({
          where: {
            orderId: order.id,
            productId: product.id,
            variantId: variantId ?? null,
          },
        });

        if (existingItem) {
          await tx.orderItem.update({
            where: {
              id: existingItem.id,
            },
            data: {
              quantity: row.quantity,
            },
          });

          result.updatedOrderItems += 1;
        } else {
          await tx.orderItem.create({
            data: {
              orderId: order.id,
              productId: product.id,
              variantId,
              quantity: row.quantity,
            },
          });

          result.createdOrderItems += 1;
        }

        const existingShipment = await tx.shipment.findUnique({
          where: {
            awb: row.awb,
          },
        });

        const shipment = await tx.shipment.upsert({
          where: {
            awb: row.awb,
          },
          update: {
            orderId: order.id,
            status: ShipmentStatus.READY_TO_PACK,
          },
          create: {
            awb: row.awb,
            orderId: order.id,
            status: ShipmentStatus.READY_TO_PACK,
          },
        });

        if (existingShipment) {
          result.updatedShipments += 1;
        } else {
          result.createdShipments += 1;
        }

        await tx.shipmentBarcode.upsert({
          where: {
            barcode: row.awb,
          },
          update: {
            shipmentId: shipment.id,
            type: "AWB",
            isActive: true,
          },
          create: {
            barcode: row.awb,
            shipmentId: shipment.id,
            type: "AWB",
            isActive: true,
          },
        });

        result.importedRows += 1;
      }
      },
      {
        timeout: 30000,
        maxWait: 10000,
      },
    );

    return result;
  }
}

export const orderImportService = new OrderImportService();
