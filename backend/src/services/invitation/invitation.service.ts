import crypto from "node:crypto";
import { prisma } from "../../config/prisma.js";

const INVITE_TTL_DAYS = 7;

export type InvitationRole =
  | "ADMIN"
  | "MANAGER"
  | "OPERATOR"
  | "VIEWER";

type DbRole =
  | "company_admin"
  | "warehouse_manager"
  | "packing_operator"
  | "viewer";

function normalizeRole(role: string): InvitationRole {
  switch (String(role || "").trim().toLowerCase()) {
    case "company_admin":
    case "admin":
      return "ADMIN";

    case "warehouse_manager":
    case "manager":
      return "MANAGER";

    case "packing_operator":
    case "operator":
      return "OPERATOR";

    case "viewer":
      return "VIEWER";

    default:
      throw new Error("INVALID_ROLE");
  }
}

function toDbRole(role: InvitationRole): DbRole {
  switch (role) {
    case "ADMIN":
      return "company_admin";
    case "MANAGER":
      return "warehouse_manager";
    case "OPERATOR":
      return "packing_operator";
    case "VIEWER":
      return "viewer";
  }
}

function hashToken(token: string): string {
  return crypto
    .createHash("sha256")
    .update(token)
    .digest("hex");
}

function newId(): string {
  return crypto.randomUUID();
}

export class InvitationService {
  /**
   * Validate invitation token.
   *
   * InviteToken contains only:
   * id, userId, tokenHash, expiresAt, usedAt, createdAt.
   *
   * All invitation metadata comes from User.
   */
  async validateToken(token: string) {
    const cleanToken = String(token || "").trim();

    if (!cleanToken) {
      throw new Error("INVALID_INVITATION");
    }

    const tokenHash = hashToken(cleanToken);

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        it.id AS "inviteTokenId",
        it."userId",
        it."expiresAt",
        it."usedAt",
        u.id AS "userId",
        u.name AS "userName",
        u.email AS "userEmail",
        u.role::text AS "userRole",
        u.status::text AS "userStatus",
        u."companyId",
        u."warehouseId",
        c."companyName",
        c.status::text AS "companyStatus",
        w.name AS "warehouseName",
        w.code AS "warehouseCode",
        w.status::text AS "warehouseStatus"
      FROM "InviteToken" it
      INNER JOIN "User" u
        ON u.id = it."userId"
      INNER JOIN "Company" c
        ON c.id = u."companyId"
      LEFT JOIN "Warehouse" w
        ON w.id = u."warehouseId"
      WHERE it."tokenHash" = $1
      LIMIT 1
      `,
      tokenHash,
    );

    const invitation = rows[0];

    if (!invitation) {
      throw new Error("INVALID_INVITATION");
    }

    if (invitation.usedAt) {
      throw new Error("INVITATION_USED");
    }

    const expiresAt = new Date(invitation.expiresAt);

    if (
      Number.isNaN(expiresAt.getTime()) ||
      expiresAt.getTime() <= Date.now()
    ) {
      throw new Error("INVITATION_EXPIRED");
    }

    if (
      String(invitation.userStatus).toLowerCase() !== "pending"
    ) {
      throw new Error("INVITATION_NOT_PENDING");
    }

    if (
      String(invitation.companyStatus).toLowerCase() !== "active"
    ) {
      throw new Error("COMPANY_INACTIVE");
    }

    if (
      invitation.warehouseId &&
      String(invitation.warehouseStatus).toLowerCase() !== "active"
    ) {
      throw new Error("WAREHOUSE_INACTIVE");
    }

    return {
      valid: true,
      invitation: {
        id: invitation.inviteTokenId,
        userId: invitation.userId,
        name: invitation.userName,
        email: invitation.userEmail,
        role: normalizeRole(invitation.userRole),
        companyId: invitation.companyId,
        companyName: invitation.companyName,
        warehouseId: invitation.warehouseId ?? null,
        warehouseName: invitation.warehouseName ?? null,
        warehouseCode: invitation.warehouseCode ?? null,
        expiresAt: expiresAt.toISOString(),
      },
    };
  }

  /**
   * Create invitation.
   *
   * Important:
   * - role comes from the authenticated admin request
   * - company scope is derived from actor unless actor is super_admin
   * - User is created as pending
   * - InviteToken references User.id
   */
  async createInvitation(input: {
    actorFirebaseUid: string;
    email: string;
    name: string;
    role: string;
    companyId?: string | null;
    warehouseId?: string | null;
    phone?: string | null;
  }) {
    const email = String(input.email || "").trim().toLowerCase();
    const name = String(input.name || "").trim();

    if (!email) {
      throw new Error("EMAIL_REQUIRED");
    }

    if (!name) {
      throw new Error("NAME_REQUIRED");
    }

    const requestedRole = normalizeRole(input.role);

    const actorRows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        u.id,
        u.email,
        u.role::text AS role,
        u.status::text AS status,
        u."companyId"
      FROM "User" u
      WHERE u."firebaseUid" = $1
      LIMIT 1
      `,
      input.actorFirebaseUid,
    );

    const actor = actorRows[0];

    if (!actor) {
      throw new Error("ACTOR_NOT_REGISTERED");
    }

    if (
      !["active"].includes(
        String(actor.status).toLowerCase(),
      )
    ) {
      throw new Error("ACTOR_INACTIVE");
    }

    const actorRole = String(actor.role).toLowerCase();

    if (
      actorRole !== "super_admin" &&
      actorRole !== "company_admin"
    ) {
      throw new Error("INVITATION_PERMISSION_DENIED");
    }

    const isPlatformAdmin = actorRole === "super_admin";

    const companyId = isPlatformAdmin
      ? String(input.companyId || "").trim()
      : actor.companyId;

    if (!companyId) {
      throw new Error("COMPANY_REQUIRED");
    }

    const companyRows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        id,
        "companyName",
        status::text AS status
      FROM "Company"
      WHERE id = $1
      LIMIT 1
      `,
      companyId,
    );

    const company = companyRows[0];

    if (!company) {
      throw new Error("COMPANY_NOT_FOUND");
    }

    if (String(company.status).toLowerCase() !== "active") {
      throw new Error("COMPANY_INACTIVE");
    }

    let warehouseId: string | null =
      input.warehouseId
        ? String(input.warehouseId).trim()
        : null;

    if (
      requestedRole === "MANAGER" ||
      requestedRole === "OPERATOR"
    ) {
      if (!warehouseId) {
        throw new Error("WAREHOUSE_REQUIRED");
      }
    }

    if (warehouseId) {
      const warehouseRows =
        await prisma.$queryRawUnsafe<any[]>(
          `
          SELECT
            id,
            "companyId",
            name,
            code,
            status::text AS status
          FROM "Warehouse"
          WHERE id = $1
            AND "companyId" = $2
          LIMIT 1
          `,
          warehouseId,
          companyId,
        );

      const warehouse = warehouseRows[0];

      if (!warehouse) {
        throw new Error("WAREHOUSE_NOT_IN_COMPANY");
      }

      if (
        String(warehouse.status).toLowerCase() !==
        "active"
      ) {
        throw new Error("WAREHOUSE_INACTIVE");
      }
    }

    const existingRows =
      await prisma.$queryRawUnsafe<any[]>(
        `
        SELECT
          id,
          status::text AS status
        FROM "User"
        WHERE LOWER(email) = LOWER($1)
          AND "companyId" = $2
        LIMIT 1
        `,
        email,
        companyId,
      );

    if (existingRows.length > 0) {
      const existing = existingRows[0];

      if (
        String(existing.status).toLowerCase() ===
        "active"
      ) {
        throw new Error("USER_ALREADY_ACTIVE");
      }

      if (
        String(existing.status).toLowerCase() ===
        "pending"
      ) {
        throw new Error("INVITATION_ALREADY_PENDING");
      }
    }

    const userId = newId();
    const inviteTokenId = newId();

    const rawToken = crypto
      .randomBytes(32)
      .toString("base64url");

    const tokenHash = hashToken(rawToken);

    const expiresAt = new Date(
      Date.now() +
        INVITE_TTL_DAYS *
          24 *
          60 *
          60 *
          1000,
    );

    const dbRoleValue = toDbRole(requestedRole);

    await prisma.$transaction(async (tx: any) => {
      await tx.$executeRawUnsafe(
        `
        INSERT INTO "User"
          (
            id,
            "firebaseUid",
            "companyId",
            "employeeId",
            name,
            email,
            phone,
            role,
            "warehouseId",
            status,
            "createdAt",
            "updatedAt"
          )
        VALUES
          (
            $1,
            NULL,
            $2,
            NULL,
            $3,
            $4,
            $5,
            $6::"Role",
            $7,
            'pending'::"UserStatus",
            NOW(),
            NOW()
          )
        `,
        userId,
        companyId,
        name,
        email,
        input.phone ?? null,
        dbRoleValue,
        warehouseId,
      );

      await tx.$executeRawUnsafe(
        `
        INSERT INTO "InviteToken"
          (
            id,
            "userId",
            "tokenHash",
            "expiresAt",
            "usedAt",
            "createdAt"
          )
        VALUES
          (
            $1,
            $2,
            $3,
            $4,
            NULL,
            NOW()
          )
        `,
        inviteTokenId,
        userId,
        tokenHash,
        expiresAt,
      );
    });

    return {
      success: true,
      invitationId: inviteTokenId,
      userId,
      token: rawToken,
      url: `/invite/${rawToken}`,
      expiresAt: expiresAt.toISOString(),
      role: requestedRole,
      companyId,
      warehouseId,
    };
  }

  /**
   * Accept invitation.
   *
   * Role/company/warehouse are read from the existing pending User.
   * The client cannot change them.
   */
  async acceptInvitation(input: {
    token: string;
    firebaseUid: string;
    firebaseEmail: string;
  }) {
    const validated = await this.validateToken(input.token);

    const invitation = validated.invitation;

    const firebaseEmail = String(
      input.firebaseEmail || "",
    )
      .trim()
      .toLowerCase();

    if (
      firebaseEmail !==
      invitation.email.trim().toLowerCase()
    ) {
      throw new Error(
        "INVITATION_EMAIL_MISMATCH",
      );
    }

    const existingIdentityRows =
      await prisma.$queryRawUnsafe<any[]>(
        `
        SELECT
          id,
          "companyId",
          "firebaseUid"
        FROM "User"
        WHERE "firebaseUid" = $1
        LIMIT 1
        `,
        input.firebaseUid,
      );

    if (existingIdentityRows.length > 0) {
      const existing =
        existingIdentityRows[0];

      if (existing.id !== invitation.userId) {
        throw new Error("USER_ALREADY_LINKED");
      }

      return {
        success: true,
        alreadyAccepted: true,
        role: invitation.role,
        companyId: invitation.companyId,
        warehouseId: invitation.warehouseId,
      };
    }

    await prisma.$transaction(async (tx: any) => {
      const updated = await tx.$executeRawUnsafe(
        `
        UPDATE "User"
        SET
          "firebaseUid" = $1,
          status = 'active'::"UserStatus",
          "updatedAt" = NOW()
        WHERE id = $2
          AND status = 'pending'::"UserStatus"
        `,
        input.firebaseUid,
        invitation.userId,
      );

      if (updated !== 1) {
        throw new Error(
          "INVITATION_NOT_PENDING",
        );
      }

      const consumed = await tx.$executeRawUnsafe(
        `
        UPDATE "InviteToken"
        SET "usedAt" = NOW()
        WHERE id = $1
          AND "usedAt" IS NULL
        `,
        invitation.id,
      );

      if (consumed !== 1) {
        throw new Error(
          "INVITATION_ALREADY_USED",
        );
      }
    });

    return {
      success: true,
      alreadyAccepted: false,
      role: invitation.role,
      companyId: invitation.companyId,
      warehouseId: invitation.warehouseId,
    };
  }
}

export default new InvitationService();
