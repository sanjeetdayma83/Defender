import type { Request, Response } from "express";
import { getAuth } from "@clerk/express";

export function getCurrentAuthUser(
  req: Request,
  res: Response,
): void {
  const auth = getAuth(req);

  if (!auth.isAuthenticated || !auth.userId) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });

    return;
  }

  res.status(200).json({
    success: true,
    user: {
      userId: auth.userId,
      sessionId: auth.sessionId ?? null,
      organizationId: auth.orgId ?? null,
    },
  });
}
