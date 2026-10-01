import "dotenv/config";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import fs from "node:fs";
import path from "node:path";

function loadServiceAccount(): Record<string, unknown> {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();

  if (raw) {
    try {
      return JSON.parse(raw) as Record<string, unknown>;
    } catch {
      throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.");
    }
  }

  const configuredPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();

  const serviceAccountPath = configuredPath
    ? path.resolve(configuredPath)
    : path.resolve(process.cwd(), "firebase-service-account.json");

  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(
      "Firebase Admin credentials are missing. Set FIREBASE_SERVICE_ACCOUNT_JSON " +
        "or FIREBASE_SERVICE_ACCOUNT_PATH.",
    );
  }

  return JSON.parse(fs.readFileSync(serviceAccountPath, "utf8")) as Record<
    string,
    unknown
  >;
}

const serviceAccount = loadServiceAccount();

const firebaseApp =
  getApps().length === 0
    ? initializeApp({
        credential: cert(serviceAccount as any),
      })
    : getApps()[0];

export const firebaseAdmin = firebaseApp;
export const firebaseAuth = getAuth(firebaseApp);

