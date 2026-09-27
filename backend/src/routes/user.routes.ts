import { Router } from "express";
import { currentUser, listUsers } from "../controllers/user.controller.js";

const router = Router();

router.get("/me", currentUser);
router.get("/", listUsers);

export default router;
