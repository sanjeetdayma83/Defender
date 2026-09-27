import { Router } from "express";
import multer from "multer";

import {
  previewImport,
  importOrders,
} from "../controllers/imports/import.controller.js";

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
    files: 1,
  },
  fileFilter: (_req, file, callback) => {
    const name = file.originalname.toLowerCase();

    const accepted =
      name.endsWith(".csv") || name.endsWith(".xlsx") || name.endsWith(".xls");

    if (!accepted) {
      callback(new Error("Only CSV, XLSX and XLS files are supported."));
      return;
    }

    callback(null, true);
  },
});

router.post("/preview", upload.single("file"), previewImport);

router.post("/", upload.single("file"), importOrders);

export default router;
