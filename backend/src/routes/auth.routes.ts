import { Router } from "express";

import { getCurrentAuthUser } from "../controllers/auth/auth.controller.js";

const router = Router();

router.get("/me", getCurrentAuthUser);

export default router;
