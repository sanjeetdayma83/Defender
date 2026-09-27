import "dotenv/config";

function required(name: string): string {
  const value = process.env[name];

  if (!value || value.trim() === "") {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value.trim();
}

export const b2Config = {
  keyId: required("B2_KEY_ID"),
  applicationKey: required("B2_APPLICATION_KEY"),
  bucketName: required("B2_BUCKET_NAME"),
  bucketId: required("B2_BUCKET_ID"),
  region: required("B2_REGION"),
  endpoint: required("B2_ENDPOINT"),
  signedUrlTtl: Number(process.env.B2_SIGNED_URL_TTL ?? "900"),
};
