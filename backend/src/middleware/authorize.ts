import type { NextFunction, Response } from "express";

import {
  hasPermission,
  type Permission,
} from "../auth/permissions.js";
import type { AppUser } from "../auth/app-user.js";
import type { AuthenticatedRequest } from "./firebase-auth.middleware.js";

export interface AuthorizedRequest extends AuthenticatedRequest {
  appUser?: AppUser;
}

export function authorize(permission: Permission) {
  return (
    req: AuthorizedRequest,
    res: Response,
    next: NextFunction,
  ): void => {
    const user = req.appUser;

    if (!user) {
      res.status(401).json({
        success: false,
        code: "AUTH_CONTEXT_MISSING",
        message: "Authentication context is unavailable.",
      });
      return;
    }

    if (!user.isActive || !user.companyIsActive) {
      res.status(403).json({
        success: false,
        code: "ACCOUNT_SUSPENDED",
        message: "Your account or company is inactive.",
      });
      return;
    }

    if (!hasPermission(user.role, permission)) {
      res.status(403).json({
        success: false,
        code: "FORBIDDEN",
        message: "You do not have permission for this action.",
        permission,
      });
      return;
    }

    next();
  };
}
