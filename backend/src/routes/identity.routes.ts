import { Router } from "express";

import {
  bootstrapCurrentUser,
  getCurrentUser,
} from "../controllers/identity/identity.controller.js";

const router = Router();

router.get("/me", getCurrentUser);
router.post("/bootstrap", bootstrapCurrentUser);

export default router;
