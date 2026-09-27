import { config } from "../../config/env.js";

export interface FlipkartTokenResponse {
  access_token: string;
  token_type: string;
  expires_in?: number;
  refresh_token?: string;
  scope?: string;
}

export async function getFlipkartAccessToken(): Promise<FlipkartTokenResponse> {
  const { appId, appSecret, apiBaseUrl } = config.flipkart;

  if (!appId || !appSecret) {
    throw new Error("Flipkart App ID or App Secret is missing.");
  }

  const credentials = Buffer.from(`${appId}:${appSecret}`).toString("base64");

  const url =
    `${apiBaseUrl}/oauth-service/oauth/token` +
    "?grant_type=client_credentials&scope=Seller_Api";

  const response = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Basic ${credentials}`,
      Accept: "application/json",
    },
  });

  const responseText = await response.text();

  if (!response.ok) {
    throw new Error(
      `Flipkart OAuth failed (${response.status}): ${responseText}`,
    );
  }

  let data: FlipkartTokenResponse;

  try {
    data = JSON.parse(responseText) as FlipkartTokenResponse;
  } catch {
    throw new Error("Flipkart OAuth returned invalid JSON.");
  }

  if (!data.access_token) {
    throw new Error("Flipkart OAuth response did not contain access_token.");
  }

  return data;
}
