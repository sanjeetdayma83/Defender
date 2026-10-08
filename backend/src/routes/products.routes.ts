import { Router } from "express";

import {
  listProducts,
  getProduct,
} from "../controllers/products/product.controller.js";
import { authorize } from "../middleware/authorize.js";
import { loadAppUser } from "../middleware/load-app-user.middleware.js";

const router = Router();

router.get(
  "/",
  loadAppUser,
  authorize("product.view"),
  listProducts,
);

router.get(
  "/:id",
  loadAppUser,
  authorize("product.view"),
  getProduct,
);

export default router;
