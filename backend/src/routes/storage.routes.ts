import { Router } from "express";
import multer from "multer";

import {
  getEvidence,
  getStorageUsage,
  getMediaUrl,
  uploadPhoto,
  uploadRecording,
} from "../controllers/storage/storage.controller.js";

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 250 * 1024 * 1024,
  },
});

router.post("/recording", upload.single("file"), uploadRecording);

router.post("/photo", upload.single("file"), uploadPhoto);

router.get("/url", getMediaUrl);

router.get("/evidence/:awb", getEvidence);

router.get("/usage", getStorageUsage);
export default router;

