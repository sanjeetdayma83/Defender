import type { Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/firebase-auth.middleware.js";

export function getCurrentAuthUser(
  req: AuthenticatedRequest,
  res: Response,
): void {
  const user = req.firebaseUser;

  if (!user) {
    res.status(401).json({
      success: false,
      message: "Authentication required.",
    });
    return;
  }

  res.status(200).json({
    success: true,
    user: {
      userId: user.uid,
      email: user.email ?? null,
      name: user.name ?? null,
      picture: user.picture ?? null,
    },
  });
}
