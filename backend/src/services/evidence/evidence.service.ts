import { prisma } from "../../config/prisma.js";

export interface CreateEvidenceInput {
  packingSessionId: string;
  type: "VIDEO" | "PHOTO";
  fileName: string;
  storageKey: string;
  contentType?: string;
  sizeBytes?: number;
  durationSeconds?: number;
}

export class EvidenceService {
  async create(input: CreateEvidenceInput) {
    const session = await prisma.packingSession.findUnique({
      where: {
        id: input.packingSessionId,
      },
      select: {
        id: true,
      },
    });

    if (!session) {
      throw new Error("Packing session not found.");
    }

    return prisma.evidenceMedia.create({
      data: {
        type: input.type,
        status: "READY",
        fileName: input.fileName,
        storageKey: input.storageKey,
        contentType: input.contentType ?? null,
        sizeBytes: input.sizeBytes ?? null,
        durationSeconds: input.durationSeconds ?? null,
        packingSessionId: input.packingSessionId,
      },
    });
  }

  async getByAwb(awb: string) {
    return prisma.evidenceMedia.findMany({
      where: {
        packingSession: {
          shipment: {
            awb,
          },
        },
      },
      include: {
        packingSession: {
          select: {
            id: true,
            status: true,
            startedAt: true,
            completedAt: true,
            orderId: true,
            shipmentId: true,
            warehouseId: true,
            userId: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });
  }
}
