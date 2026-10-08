import { Router } from "express";
import invitationController from "../controllers/invitation/invitation.controller.js";
import { authorize } from "../middleware/authorize.js";
import { firebaseAuthMiddleware } from "../middleware/firebase-auth.middleware.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.get(
  "/:token",
  invitationController.getInvitation,
);

router.post(
  "/",
  firebaseAuthMiddleware,
  loadAppUser,
  authorize("team.invite"),
  invitationController.createInvitation,
);

router.post(
  "/:token/accept",
  firebaseAuthMiddleware,
  invitationController.acceptInvitation,
);

export default router;
