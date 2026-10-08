import { Router } from "express";
import multer from "multer";

import {
  getEvidence,
  getStorageUsage,
  getMediaUrl,
  uploadPhoto,
  uploadRecording,
} from "../controllers/storage/storage.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 250 * 1024 * 1024,
  },
});

router.post(
  "/recording",
  loadAppUser,
  authorize("recording.upload"),
  upload.single("file"),
  uploadRecording,
);

router.post(
  "/photo",
  loadAppUser,
  authorize("recording.upload"),
  upload.single("file"),
  uploadPhoto,
);

router.get(
  "/url",
  loadAppUser,
  authorize("evidence.download"),
  getMediaUrl,
);

router.get(
  "/evidence/:awb",
  loadAppUser,
  authorize("evidence.view"),
  getEvidence,
);

router.get(
  "/usage",
  loadAppUser,
  authorize("usage.view_team"),
  getStorageUsage,
);

export default router;
