import { Router } from "express";

import {
  bootstrapCurrentUser,
  getCurrentUser,
} from "../controllers/identity/identity.controller.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.get("/me", loadAppUser, getCurrentUser);
router.post("/bootstrap", bootstrapCurrentUser);

export default router;
