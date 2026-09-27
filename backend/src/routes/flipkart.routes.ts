import { Router } from "express";
import { getFlipkartAccessToken } from "../services/flipkart/flipkart-auth.service.js";

const router = Router();

router.get("/token-test", async (_req, res) => {
  try {
    const token = await getFlipkartAccessToken();

    res.status(200).json({
      success: true,
      message: "Flipkart OAuth authentication successful.",
      tokenType: token.token_type,
      expiresIn: token.expires_in ?? null,
      hasRefreshToken: Boolean(token.refresh_token),
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown Flipkart OAuth error.";

    res.status(502).json({
      success: false,
      message,
    });
  }
});

export default router;
