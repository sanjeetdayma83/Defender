import { Router } from "express";
import invitationController from "../controllers/invitation/invitation.controller.js";
import { firebaseAuthMiddleware } from "../middleware/firebase-auth.middleware.js";

const router = Router();

router.get(
  "/:token",
  invitationController.getInvitation
);

router.post(
  "/",
  firebaseAuthMiddleware,
  invitationController.createInvitation
);

router.post(
  "/:token/accept",
  firebaseAuthMiddleware,
  invitationController.acceptInvitation
);

export default router;
