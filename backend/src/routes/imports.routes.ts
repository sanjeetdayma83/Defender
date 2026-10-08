import { Router } from "express";
import multer from "multer";

import {
  importOrders,
  previewOrdersImport,
} from "../controllers/imports/import.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 25 * 1024 * 1024,
  },
});

router.post(
  "/preview",
  loadAppUser,
  authorize("order.import"),
  upload.single("file"),
  previewOrdersImport,
);

router.post(
  "/orders",
  loadAppUser,
  authorize("order.import"),
  upload.single("file"),
  importOrders,
);

export default router;
