import { prisma } from "../../config/prisma.js";

export interface StartPackingInput {
  awb: string;
  warehouseId: string;
  firebaseUid: string;
  email?: string;
  name?: string;
}

export class PackingService {
  async start(input: StartPackingInput) {
    const awb = input.awb.trim();

    if (!awb) {
      throw new Error("AWB is required.");
    }

    const warehouse = await prisma.warehouse.findUnique({
      where: {
        id: input.warehouseId,
      },
      select: {
        id: true,
        companyId: true,
        isActive: true,
      },
    });

    if (!warehouse) {
      throw new Error("Warehouse not found.");
    }

    if (!warehouse.isActive) {
      throw new Error("Warehouse is inactive.");
    }

    const shipment = await prisma.shipment.findUnique({
      where: {
        awb,
      },
      include: {
        order: true,
      },
    });

    if (!shipment) {
      throw new Error("Shipment not found for this AWB.");
    }

    if (shipment.order.companyId !== warehouse.companyId) {
      throw new Error("Shipment does not belong to this warehouse company.");
    }

    const user = await prisma.user.upsert({
      where: {
        firebaseUid: input.firebaseUid,
      },
      update: {
        email: input.email ?? undefined,
        name: input.name ?? undefined,
      },
      create: {
        firebaseUid: input.firebaseUid,
        email: input.email ?? "unknown@lossdefender.in",
        name: input.name ?? null,
        role: "OPERATOR",
        companyId: warehouse.companyId,
      },
    });

    if (user.companyId !== warehouse.companyId) {
      throw new Error("Authenticated user does not belong to this company.");
    }

    const existing = await prisma.packingSession.findFirst({
      where: {
        shipmentId: shipment.id,
        status: "ACTIVE",
        userId: user.id,
      },
      include: {
        order: true,
        shipment: true,
        media: true,
      },
      orderBy: {
        startedAt: "desc",
      },
    });

    if (existing) {
      return existing;
    }

    const session = await prisma.$transaction(async (tx) => {
      const created = await tx.packingSession.create({
        data: {
          orderId: shipment.orderId,
          shipmentId: shipment.id,
          warehouseId: warehouse.id,
          userId: user.id,
          status: "ACTIVE",
          startedAt: new Date(),
        },
        include: {
          order: true,
          shipment: true,
          media: true,
        },
      });

      await tx.shipment.update({
        where: {
          id: shipment.id,
        },
        data: {
          status: "PACKING",
        },
      });

      await tx.order.update({
        where: {
          id: shipment.orderId,
        },
        data: {
          status: "PACKING",
        },
      });

      return created;
    });

    return session;
  }

  async get(id: string) {
    return prisma.packingSession.findUnique({
      where: {
        id,
      },
      include: {
        order: true,
        shipment: true,
        warehouse: true,
        user: true,
        media: true,
      },
    });
  }

  async complete(id: string) {
    const session = await prisma.packingSession.findUnique({
      where: {
        id,
      },
    });

    if (!session) {
      throw new Error("Packing session not found.");
    }

    const result = await prisma.$transaction(async (tx) => {
      const completed = await tx.packingSession.update({
        where: {
          id,
        },
        data: {
          status: "COMPLETED",
          completedAt: new Date(),
        },
        include: {
          order: true,
          shipment: true,
          media: true,
        },
      });

      await tx.shipment.update({
        where: {
          id: session.shipmentId,
        },
        data: {
          status: "PACKED",
        },
      });

      await tx.order.update({
        where: {
          id: session.orderId,
        },
        data: {
          status: "PACKED",
        },
      });

      return completed;
    });

    return result;
  }

  async cancel(id: string) {
    const session = await prisma.packingSession.findUnique({
      where: {
        id,
      },
    });

    if (!session) {
      throw new Error("Packing session not found.");
    }

    return prisma.$transaction(async (tx) => {
      const cancelled = await tx.packingSession.update({
        where: {
          id,
        },
        data: {
          status: "CANCELLED",
          completedAt: new Date(),
        },
        include: {
          order: true,
          shipment: true,
          media: true,
        },
      });

      await tx.shipment.update({
        where: {
          id: session.shipmentId,
        },
        data: {
          status: "READY_TO_PACK",
        },
      });

      await tx.order.update({
        where: {
          id: session.orderId,
        },
        data: {
          status: "PENDING",
        },
      });

      return cancelled;
    });
  }

  async getByShipment(shipmentId: string) {
    return prisma.packingSession.findMany({
      where: {
        shipmentId,
      },
      include: {
        media: true,
        order: true,
        shipment: true,
        user: true,
      },
      orderBy: {
        startedAt: "desc",
      },
    });
  }
}
