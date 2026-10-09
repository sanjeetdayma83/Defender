import type { Response } from "express";

import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";
import { companyContextService } from "../../services/identity/company-context.service.js";
import { prisma } from "../../config/prisma.js";

export async function listShipments(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const firebaseUid = req.firebaseUser?.uid;

  if (!firebaseUid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  const { company } = await companyContextService.getCompany(firebaseUid);

  const search = String(req.query.search ?? "").trim();

  const shipments = await prisma.shipment.findMany({
    where: {
      order: {
        companyId: company.id,
      },
      ...(search
        ? {
            OR: [
              {
                awb: {
                  contains: search,
                  mode: "insensitive",
                },
              },
              {
                order: {
                  marketplaceOrderId: {
                    contains: search,
                    mode: "insensitive",
                  },
                },
              },
            ],
          }
        : {}),
    },
    include: {
      order: {
        include: {
          orderItems: {
            include: {
              product: true,
              variant: true,
            },
          },
        },
      },
      barcodeAliases: true,
    },
    orderBy: {
      createdAt: "desc",
    },
    take: 100,
  });

  res.json({
    success: true,
    data: shipments,
  });
}

export async function getShipment(
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> {
  const firebaseUid = req.firebaseUser?.uid;

  if (!firebaseUid) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  const { company } = await companyContextService.getCompany(firebaseUid);

  const shipment = await prisma.shipment.findFirst({
    where: {
      id: String(req.params.id),
      order: {
        companyId: company.id,
      },
    },
    include: {
      barcodeAliases: true,
      order: {
        include: {
          Warehouse: true,
          orderItems: {
            include: {
              product: {
                include: {
                  variants: true,
                },
              },
              variant: true,
            },
          },
        },
      },
    },
  });

  if (!shipment) {
    res.status(404).json({
      success: false,
      message: "Shipment not found.",
    });
    return;
  }

  res.json({
    success: true,
    data: shipment,
  });
}
