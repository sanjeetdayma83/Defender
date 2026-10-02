import { randomUUID } from "node:crypto";
import { prisma } from "../../config/prisma.js";
import { scanWalletService } from "../scan-wallet/scan-wallet.service.js";

export interface StartPackingInput {
  awb: string;
  warehouseId: string;
  firebaseUid: string;
  email?: string;
  name?: string;
}

type RecordingRow = {
  id: string;
  companyId: string;
  operatorId: string;
  stationId: string | null;
  status: string;
  startedAt: Date;
  stoppedAt: Date | null;
  segmentCount: number;
  b2KeyPrefix: string | null;
  createdAt: Date;
  orderId: string | null;
  mode: string;
};

function mapRecording(row: RecordingRow) {
  return {
    id: row.id,
    companyId: row.companyId,
    operatorId: row.operatorId,
    stationId: row.stationId,
    status: row.status,
    startedAt: row.startedAt,
    stoppedAt: row.stoppedAt,
    segmentCount: row.segmentCount,
    b2KeyPrefix: row.b2KeyPrefix,
    createdAt: row.createdAt,
    orderId: row.orderId,
    mode: row.mode,
  };
}

async function getRecordingById(
  id: string,
  companyId: string,
): Promise<RecordingRow | null> {
  const rows = await prisma.$queryRawUnsafe<RecordingRow[]>(
    `
      SELECT
        id,
        "companyId",
        "operatorId",
        "stationId",
        status,
        "startedAt",
        "stoppedAt",
        "segmentCount",
        "b2KeyPrefix",
        "createdAt",
        "orderId",
        mode
      FROM "Recording"
      WHERE id = $1
        AND "companyId" = $2
      LIMIT 1
    `,
    id,
    companyId,
  );

  return rows[0] ?? null;
}

export class PackingService {
  async start(input: StartPackingInput) {
    const awb = String(input.awb ?? "").trim();

    if (!awb) {
      throw new Error("AWB is required.");
    }

    if (!input.warehouseId?.trim()) {
      throw new Error("Warehouse ID is required.");
    }

    if (!input.firebaseUid?.trim()) {
      throw new Error("Authenticated Firebase user is required.");
    }

    const context = await prisma.$queryRawUnsafe<
      Array<{
        userId: string;
        userCompanyId: string;
        userRole: string;
        userStatus: string;
        userWarehouseId: string | null;
        userStationId: string | null;
        warehouseId: string;
        warehouseCompanyId: string;
        warehouseStatus: string;
        orderId: string;
        orderCompanyId: string;
        orderWarehouseId: string | null;
        orderStatus: string;
        orderAwb: string | null;
        marketplaceOrderId: string | null;
      }>
    >(
      `
        SELECT
          u.id AS "userId",
          u."companyId" AS "userCompanyId",
          u.role::text AS "userRole",
          u.status::text AS "userStatus",
          u."warehouseId" AS "userWarehouseId",
          u."stationId" AS "userStationId",

          w.id AS "warehouseId",
          w."companyId" AS "warehouseCompanyId",
          w.status::text AS "warehouseStatus",

          o.id AS "orderId",
          o."companyId" AS "orderCompanyId",
          o."warehouseId" AS "orderWarehouseId",
          o.status::text AS "orderStatus",
          o.awb AS "orderAwb",
          o."marketplaceOrderId" AS "marketplaceOrderId"
        FROM "User" u
        JOIN "Warehouse" w
          ON w.id = $2
        JOIN "Order" o
          ON o.awb = $3
        WHERE u."clerkId" = $1
        LIMIT 1
      `,
      input.firebaseUid.trim(),
      input.warehouseId.trim(),
      awb,
    );

    if (context.length === 0) {
      const userRows = await prisma.$queryRawUnsafe<
        Array<{
          id: string;
          companyId: string;
          role: string;
          status: string;
          warehouseId: string | null;
        }>
      >(
        `
          SELECT
            id,
            "companyId",
            role::text AS role,
            status::text AS status,
            "warehouseId"
          FROM "User"
          WHERE "clerkId" = $1
          LIMIT 1
        `,
        input.firebaseUid.trim(),
      );

      if (userRows.length === 0) {
        throw new Error("Authenticated user is not registered.");
      }

      if (userRows[0].status !== "active") {
        throw new Error("User account is inactive.");
      }

      throw new Error(
        "Warehouse or order not found for the authenticated company.",
      );
    }

    const row = context[0];

    if (row.userStatus !== "active") {
      throw new Error("User account is inactive.");
    }

    if (
      row.userRole !== "company_admin" &&
      row.userRole !== "packing_operator"
    ) {
      throw new Error("User is not authorized for packing.");
    }

    if (row.warehouseStatus !== "active") {
      throw new Error("Warehouse is inactive.");
    }

    if (row.userCompanyId !== row.warehouseCompanyId) {
      throw new Error("Authenticated user does not belong to this company.");
    }

    if (row.orderCompanyId !== row.warehouseCompanyId) {
      throw new Error("Shipment does not belong to this warehouse company.");
    }

    if (
      row.orderWarehouseId &&
      row.orderWarehouseId !== row.warehouseId
    ) {
      throw new Error("Order does not belong to the selected warehouse.");
    }

    if (
      row.userWarehouseId &&
      row.userWarehouseId !== row.warehouseId
    ) {
      throw new Error("User is not assigned to the selected warehouse.");
    }

    const existing = await prisma.$queryRawUnsafe<RecordingRow[]>(
      `
        SELECT
          id,
          "companyId",
          "operatorId",
          "stationId",
          status,
          "startedAt",
          "stoppedAt",
          "segmentCount",
          "b2KeyPrefix",
          "createdAt",
          "orderId",
          mode
        FROM "Recording"
        WHERE "companyId" = $1
          AND "operatorId" = $2
          AND "orderId" = $3
          AND status IN ('started', 'paused')
        ORDER BY "startedAt" DESC
        LIMIT 1
      `,
      row.userCompanyId,
      row.userId,
      row.orderId,
    );

    if (existing[0]) {
      return mapRecording(existing[0]);
    }

    const recordingId = randomUUID();
    const idempotencyKey = `packing-recording:${recordingId}:scan`;

    const recording = await prisma.$transaction(async (tx) => {
      await scanWalletService.consumeScansInTransaction(tx, {
        companyId: row.userCompanyId,
        credits: 1,
        referenceType: "PACKING_RECORDING",
        referenceId: recordingId,
        idempotencyKey,
        description: `Packing scan for AWB ${awb}`,
      });

      await tx.$executeRawUnsafe(
        `
          INSERT INTO "Recording" (
            id,
            "companyId",
            "operatorId",
            "stationId",
            status,
            "startedAt",
            "stoppedAt",
            "segmentCount",
            "b2KeyPrefix",
            "createdAt",
            "orderId",
            mode
          )
          VALUES (
            $1,
            $2,
            $3,
            $4,
            'started'::"RecordingStatus",
            CURRENT_TIMESTAMP,
            NULL,
            0,
            $5,
            CURRENT_TIMESTAMP,
            $6,
            'forward'::"RecordingMode"
          )
        `,
        recordingId,
        row.userCompanyId,
        row.userId,
        row.userStationId,
        `companies/${row.userCompanyId}/recordings/${recordingId}`,
        row.orderId,
      );

      await tx.$executeRawUnsafe(
        `
          UPDATE "Order"
          SET
            "assignedOperatorId" = $1,
            "updatedAt" = CURRENT_TIMESTAMP
          WHERE id = $2
            AND "companyId" = $3
        `,
        row.userId,
        row.orderId,
        row.userCompanyId,
      );

      const created = await tx.$queryRawUnsafe<RecordingRow[]>(
        `
          SELECT
            id,
            "companyId",
            "operatorId",
            "stationId",
            status,
            "startedAt",
            "stoppedAt",
            "segmentCount",
            "b2KeyPrefix",
            "createdAt",
            "orderId",
            mode
          FROM "Recording"
          WHERE id = $1
            AND "companyId" = $2
          LIMIT 1
        `,
        recordingId,
        row.userCompanyId,
      );

      if (!created[0]) {
        throw new Error("Unable to create recording.");
      }

      return created[0];
    });

    return mapRecording(recording);
  }

  async get(id: string) {
    if (!id?.trim()) {
      throw new Error("Recording ID is required.");
    }

    const rows = await prisma.$queryRawUnsafe<RecordingRow[]>(
      `
        SELECT
          r.id,
          r."companyId",
          r."operatorId",
          r."stationId",
          r.status,
          r."startedAt",
          r."stoppedAt",
          r."segmentCount",
          r."b2KeyPrefix",
          r."createdAt",
          r."orderId",
          r.mode
        FROM "Recording" r
        WHERE r.id = $1
          AND r."companyId" = (
            SELECT "companyId"
            FROM "User"
            WHERE id = r."operatorId"
            LIMIT 1
          )
        LIMIT 1
      `,
      id,
    );

    return rows[0] ? mapRecording(rows[0]) : null;
  }

  async complete(id: string) {
    if (!id?.trim()) {
      throw new Error("Recording ID is required.");
    }

    const existing = await prisma.$queryRawUnsafe<
      Array<RecordingRow & { evidenceCount: number }>
    >(
      `
        SELECT
          r.id,
          r."companyId",
          r."operatorId",
          r."stationId",
          r.status,
          r."startedAt",
          r."stoppedAt",
          r."segmentCount",
          r."b2KeyPrefix",
          r."createdAt",
          r."orderId",
          r.mode,
          (
            SELECT COUNT(*)::int
            FROM "Evidence" e
            WHERE e."recordingId" = r.id
              AND e."companyId" = r."companyId"
          ) AS "evidenceCount"
        FROM "Recording" r
        WHERE r.id = $1
        LIMIT 1
      `,
      id,
    );

    if (!existing[0]) {
      throw new Error("Recording not found.");
    }

    const result = await prisma.$transaction(async (tx) => {
      await tx.$executeRawUnsafe(
        `
          UPDATE "Recording"
          SET
            status = 'completed'::"RecordingStatus",
            "stoppedAt" = COALESCE("stoppedAt", CURRENT_TIMESTAMP)
          WHERE id = $1
        `,
        id,
      );

      if (existing[0].orderId && existing[0].evidenceCount > 0) {
        await tx.$executeRawUnsafe(
          `
            UPDATE "Order"
            SET
              status = 'evidence_ready'::"OrderStatus",
              "updatedAt" = CURRENT_TIMESTAMP
            WHERE id = $1
              AND "companyId" = $2
          `,
          existing[0].orderId,
          existing[0].companyId,
        );
      }

      const rows = await tx.$queryRawUnsafe<RecordingRow[]>(
        `
          SELECT
            id,
            "companyId",
            "operatorId",
            "stationId",
            status,
            "startedAt",
            "stoppedAt",
            "segmentCount",
            "b2KeyPrefix",
            "createdAt",
            "orderId",
            mode
          FROM "Recording"
          WHERE id = $1
          LIMIT 1
        `,
        id,
      );

      if (!rows[0]) {
        throw new Error("Recording not found after completion.");
      }

      return rows[0];
    });

    return mapRecording(result);
  }

  async cancel(id: string) {
    if (!id?.trim()) {
      throw new Error("Recording ID is required.");
    }

    const existing = await prisma.$queryRawUnsafe<RecordingRow[]>(
      `
        SELECT
          id,
          "companyId",
          "operatorId",
          "stationId",
          status,
          "startedAt",
          "stoppedAt",
          "segmentCount",
          "b2KeyPrefix",
          "createdAt",
          "orderId",
          mode
        FROM "Recording"
        WHERE id = $1
        LIMIT 1
      `,
      id,
    );

    if (!existing[0]) {
      throw new Error("Recording not found.");
    }

    const result = await prisma.$transaction(async (tx) => {
      await tx.$executeRawUnsafe(
        `
          UPDATE "Recording"
          SET
            status = 'failed'::"RecordingStatus",
            "stoppedAt" = COALESCE("stoppedAt", CURRENT_TIMESTAMP)
          WHERE id = $1
        `,
        id,
      );

      const rows = await tx.$queryRawUnsafe<RecordingRow[]>(
        `
          SELECT
            id,
            "companyId",
            "operatorId",
            "stationId",
            status,
            "startedAt",
            "stoppedAt",
            "segmentCount",
            "b2KeyPrefix",
            "createdAt",
            "orderId",
            mode
          FROM "Recording"
          WHERE id = $1
          LIMIT 1
        `,
        id,
      );

      if (!rows[0]) {
        throw new Error("Recording not found after cancellation.");
      }

      return rows[0];
    });

    return mapRecording(result);
  }

  async getByShipment(shipmentId: string) {
    if (!shipmentId?.trim()) {
      throw new Error("Shipment ID is required.");
    }

    const rows = await prisma.$queryRawUnsafe<RecordingRow[]>(
      `
        SELECT
          r.id,
          r."companyId",
          r."operatorId",
          r."stationId",
          r.status,
          r."startedAt",
          r."stoppedAt",
          r."segmentCount",
          r."b2KeyPrefix",
          r."createdAt",
          r."orderId",
          r.mode
        FROM "Recording" r
        JOIN "Order" o
          ON o.id = r."orderId"
        WHERE o.id = $1
          AND r."companyId" = o."companyId"
        ORDER BY r."startedAt" DESC
      `,
      shipmentId,
    );

    return rows.map(mapRecording);
  }
}

export const packingService = new PackingService();
