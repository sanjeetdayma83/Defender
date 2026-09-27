import { prisma } from "../../config/prisma.js";

export class ScanWalletService {
  async getOrCreate(companyId: string) {
    return prisma.scanWallet.upsert({
      where: {
        companyId,
      },
      create: {
        companyId,
        balance: 0,
        lifetimeAllocated: 0,
        lifetimeConsumed: 0,
      },
      update: {},
      include: {
        transactions: {
          orderBy: {
            createdAt: "desc",
          },
          take: 20,
        },
      },
    });
  }

  async get(companyId: string) {
    return this.getOrCreate(companyId);
  }

  async allocate(
    companyId: string,
    credits: number,
    description: string,
    referenceType?: string,
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    if (!Number.isInteger(credits) || credits <= 0) {
      throw new Error("Credits must be a positive integer.");
    }

    return prisma.$transaction(async (tx) => {
      const wallet = await tx.scanWallet.upsert({
        where: {
          companyId,
        },
        create: {
          companyId,
          balance: 0,
        },
        update: {},
      });

      if (idempotencyKey) {
        const existing = await tx.scanTransaction.findUnique({
          where: {
            idempotencyKey,
          },
        });

        if (existing) {
          return existing;
        }
      }

      const balanceAfter = wallet.balance + credits;

      const transaction = await tx.scanTransaction.create({
        data: {
          walletId: wallet.id,
          companyId,
          type: "ALLOCATION",
          credits,
          balanceAfter,
          referenceType,
          referenceId,
          idempotencyKey,
          description,
        },
      });

      await tx.scanWallet.update({
        where: {
          id: wallet.id,
        },
        data: {
          balance: balanceAfter,
          lifetimeAllocated: {
            increment: credits,
          },
        },
      });

      return transaction;
    });
  }

  async consume(
    companyId: string,
    credits = 1,
    description = "Packing scan",
    referenceType?: string,
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    if (!Number.isInteger(credits) || credits <= 0) {
      throw new Error("Credits must be a positive integer.");
    }

    return prisma.$transaction(async (tx) => {
      const wallet = await tx.scanWallet.findUnique({
        where: {
          companyId,
        },
      });

      if (!wallet) {
        throw new Error("Scan wallet not found.");
      }

      if (wallet.balance < credits) {
        throw new Error("INSUFFICIENT_SCAN_CREDITS");
      }

      if (idempotencyKey) {
        const existing = await tx.scanTransaction.findUnique({
          where: {
            idempotencyKey,
          },
        });

        if (existing) {
          return existing;
        }
      }

      const balanceAfter = wallet.balance - credits;

      const transaction = await tx.scanTransaction.create({
        data: {
          walletId: wallet.id,
          companyId,
          type: "CONSUMPTION",
          credits: -credits,
          balanceAfter,
          referenceType,
          referenceId,
          idempotencyKey,
          description,
        },
      });

      await tx.scanWallet.update({
        where: {
          id: wallet.id,
        },
        data: {
          balance: balanceAfter,
          lifetimeConsumed: {
            increment: credits,
          },
        },
      });

      return transaction;
    });
  }

  async topUp(
    companyId: string,
    credits: number,
    description = "Scan credit top-up",
    referenceType?: string,
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    return this.allocate(
      companyId,
      credits,
      description,
      referenceType,
      referenceId,
      idempotencyKey,
    );
  }

  async refund(
    companyId: string,
    credits: number,
    description = "Scan credit refund",
    referenceType?: string,
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    if (!Number.isInteger(credits) || credits <= 0) {
      throw new Error("Credits must be a positive integer.");
    }

    return prisma.$transaction(async (tx) => {
      const wallet = await tx.scanWallet.upsert({
        where: {
          companyId,
        },
        create: {
          companyId,
          balance: 0,
        },
        update: {},
      });

      if (idempotencyKey) {
        const existing = await tx.scanTransaction.findUnique({
          where: {
            idempotencyKey,
          },
        });

        if (existing) {
          return existing;
        }
      }

      const balanceAfter = wallet.balance + credits;

      const transaction = await tx.scanTransaction.create({
        data: {
          walletId: wallet.id,
          companyId,
          type: "REFUND",
          credits,
          balanceAfter,
          referenceType,
          referenceId,
          idempotencyKey,
          description,
        },
      });

      await tx.scanWallet.update({
        where: {
          id: wallet.id,
        },
        data: {
          balance: balanceAfter,
        },
      });

      return transaction;
    });
  }
}

export const scanWalletService = new ScanWalletService();
