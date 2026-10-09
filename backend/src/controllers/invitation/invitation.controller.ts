import type { Request, Response } from "express";
import invitationService from "../../services/invitation/invitation.service.js";

function errorResponse(error: unknown) {
  const code = error instanceof Error ? error.message : "UNKNOWN_ERROR";

  const map: Record<string, { status: number; message: string }> = {
    INVALID_INVITATION: {
      status: 404,
      message: "This invitation link is invalid.",
    },
    INVITATION_EXPIRED: {
      status: 410,
      message: "This invitation link has expired.",
    },
    INVITATION_USED: {
      status: 409,
      message: "This invitation has already been used.",
    },
    INVITATION_EMAIL_MISMATCH: {
      status: 403,
      message: "This invitation belongs to a different email address.",
    },
    USER_ALREADY_LINKED: {
      status: 409,
      message: "This account is already linked to another workspace.",
    },
    USER_NOT_REGISTERED: {
      status: 404,
      message: "Invitation user profile was not found.",
    },
    COMPANY_INACTIVE: {
      status: 403,
      message: "This company is not active.",
    },
    WAREHOUSE_REQUIRED: {
      status: 400,
      message: "A warehouse is required for this role.",
    },
    INVALID_ROLE: {
      status: 400,
      message: "The invitation role is invalid.",
    },
    EMAIL_REQUIRED: {
      status: 400,
      message: "Email is required.",
    },
  };

  return (
    map[code] ?? {
      status: 500,
      message: "Something went wrong while processing the invitation.",
    }
  );
}

const invitationController = {
  async getInvitation(req: Request, res: Response) {
    try {
      const token = Array.isArray(req.params.token) ? req.params.token[0] : req.params.token;
      const result = await invitationService.validateToken(token);

      return res.status(200).json({
        success: true,
        ...result,
      });
    } catch (error) {
      const mapped = errorResponse(error);

      return res.status(mapped.status).json({
        success: false,
        code:
          error instanceof Error ? error.message : "UNKNOWN_ERROR",
        message: mapped.message,
      });
    }
  },

  async createInvitation(req: Request, res: Response) {
    try {
      const firebaseUser = (req as any).firebaseUser;

      if (!firebaseUser?.uid) {
        return res.status(401).json({
          success: false,
          code: "UNAUTHORIZED",
          message: "Authentication is required.",
        });
      }

      const result = await invitationService.createInvitation({
        actorFirebaseUid: firebaseUser.uid,
        email: req.body?.email,
        name: req.body?.name,
        role: req.body?.role,
        companyId: req.body?.companyId,
        warehouseId: req.body?.warehouseId,
        phone: req.body?.phone,
      });

      return res.status(201).json(result);
    } catch (error) {
      const mapped = errorResponse(error);

      return res.status(mapped.status).json({
        success: false,
        code:
          error instanceof Error ? error.message : "UNKNOWN_ERROR",
        message: mapped.message,
      });
    }
  },

  async acceptInvitation(req: Request, res: Response) {
    try {
      const firebaseUser = (req as any).firebaseUser;

      if (!firebaseUser?.uid) {
        return res.status(401).json({
          success: false,
          code: "UNAUTHORIZED",
          message: "Authentication is required.",
        });
      }

      if (firebaseUser.emailVerified !== true) {
        return res.status(403).json({
          success: false,
          code: "EMAIL_NOT_VERIFIED",
          message: "Verify your email address before accepting this invitation.",
        });
      }

      if (!firebaseUser.email) {
        return res.status(400).json({
          success: false,
          code: "EMAIL_REQUIRED",
          message: "Your authenticated account does not have an email.",
        });
      }

      const result = await invitationService.acceptInvitation({
        token: Array.isArray(req.params.token) ? req.params.token[0] : req.params.token,
        firebaseUid: firebaseUser.uid,
        firebaseEmail: firebaseUser.email,
      });

      return res.status(200).json(result);
    } catch (error) {
      const mapped = errorResponse(error);

      return res.status(mapped.status).json({
        success: false,
        code:
          error instanceof Error ? error.message : "UNKNOWN_ERROR",
        message: mapped.message,
      });
    }
  },
};

export default invitationController;


