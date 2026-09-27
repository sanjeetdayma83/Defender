import "dotenv/config";

function getPort(): number {
  const value = process.env.PORT ?? "4000";
  const port = Number(value);

  if (!Number.isInteger(port) || port <= 0) {
    throw new Error(`Invalid PORT value: ${value}`);
  }

  return port;
}

export const config = {
  port: getPort(),
  nodeEnv: process.env.NODE_ENV ?? "development",

  flipkart: {
    appId: process.env.FLIPKART_APP_ID ?? "",
    appSecret: process.env.FLIPKART_APP_SECRET ?? "",
    apiBaseUrl: process.env.FLIPKART_API_BASE_URL ?? "https://api.flipkart.net",
  },
};
