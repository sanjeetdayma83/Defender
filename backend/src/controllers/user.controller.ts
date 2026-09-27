import type { Response } from "express";
import type { AuthenticatedRequest } from "../middleware/firebase-auth.middleware.js";
import { UserService } from "../services/users/user.service.js";

const service = new UserService();

export async function currentUser(req: AuthenticatedRequest, res: Response) {
  try {
    const uid = req.firebaseUser?.uid;

    if (!uid) {
      return res.status(401).json({
        success: false,
        message: "Authenticated user is unavailable.",
      });
    }

    const user = await service.findByFirebaseUid(uid);

    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_REGISTERED",
        message: "Authenticated Firebase user is not registered.",
      });
    }

    return res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Current user lookup failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to load current user.",
    });
  }
}

export async function listUsers(_req: AuthenticatedRequest, res: Response) {
  try {
    const users = await service.list();

    return res.json({
      success: true,
      data: users,
    });
  } catch (error) {
    console.error("User listing failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to load users.",
    });
  }
}
