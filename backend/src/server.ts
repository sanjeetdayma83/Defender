import "dotenv/config";

import { app } from "./app.js";

const PORT = Number(process.env.PORT ?? 4000);
const HOST = process.env.HOST ?? "0.0.0.0";

if (!Number.isInteger(PORT) || PORT <= 0 || PORT > 65535) {
  throw new Error(`Invalid PORT value: ${process.env.PORT ?? ""}`);
}

const server = app.listen(PORT, HOST, () => {
  console.log("");
  console.log("============================================================");
  console.log(" LOSS DEFENDER BACKEND");
  console.log("============================================================");
  console.log(`HTTP server: http://localhost:${PORT}`);
  console.log(`Health:      http://localhost:${PORT}/api/v1/health`);
  console.log(`Host:        ${HOST}`);
  console.log(`Environment: ${process.env.NODE_ENV ?? "development"}`);
  console.log("============================================================");
  console.log("");
});

server.on("error", (error: NodeJS.ErrnoException) => {
  console.error("");
  console.error("============================================================");
  console.error(" LOSS DEFENDER BACKEND STARTUP ERROR");
  console.error("============================================================");

  if (error.code === "EADDRINUSE") {
    console.error(`Port ${PORT} is already in use.`);
    console.error(`Stop the process using port ${PORT} and restart.`);
  } else {
    console.error(error);
  }

  console.error("============================================================");
  process.exit(1);
});

function shutdown(signal: string): void {
  console.log(`\nReceived ${signal}. Shutting down...`);

  server.close((error) => {
    if (error) {
      console.error("Shutdown error:", error);
      process.exit(1);
    }

    console.log("Backend stopped.");
    process.exit(0);
  });
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
