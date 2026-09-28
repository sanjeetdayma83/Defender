import { Router } from "express";
import multer from "multer";

import {
  importOrders,
  previewOrdersImport,
} from "../controllers/imports/import.controller.js";

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 25 * 1024 * 1024,
  },
});

router.post("/preview", upload.single("file"), previewOrdersImport);

router.post("/orders", upload.single("file"), importOrders);

export default router;
