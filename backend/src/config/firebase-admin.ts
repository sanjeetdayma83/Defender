import { cert, getApps, initializeApp } from "firebase-admin/app";

import { getAuth } from "firebase-admin/auth";

import fs from "node:fs";
import path from "node:path";

const serviceAccountPath = path.resolve(
  process.cwd(),
  "firebase-service-account.json",
);

if (!fs.existsSync(serviceAccountPath)) {
  throw new Error(
    "firebase-service-account.json was not found in the backend root.",
  );
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));

const firebaseApp =
  getApps().length === 0
    ? initializeApp({
        credential: cert(serviceAccount),
      })
    : getApps()[0];

export const firebaseAdmin = firebaseApp;
export const firebaseAuth = getAuth(firebaseApp);
