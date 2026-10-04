import { Router } from "express";
import {
  listPlatformUsers,
  setUserStatus,
} from "../controllers/platform/users.controller.js";

const router = Router();

router.get("/", listPlatformUsers);
router.patch("/:id/status", setUserStatus);

export default router;
